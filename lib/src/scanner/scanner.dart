import 'package:fpdart/fpdart.dart';

import '../failures/compile_failure.dart';
import '../tokens/token.dart';
import '../tokens/token_type.dart';
import 'scanner_table.dart';

/// Sentinel used to mark end-of-input (the original stream produced `null`).
const String _eofChar = '\uFFFF';

/// Reserved keyword table for scanning a program source file.
///
/// Maps a keyword kind to the exact lexeme the scanner must read to recognize
/// it (e.g. `TokenType.begin` → `begin`). Kept separate from the grammar
/// dictionary because the program vocabulary and the grammar-file vocabulary
/// reserve different spellings (runtime uses lowercase `read`, grammar files
/// use `Read`).
const Map<TokenType, String> programReservedTokens = {
  TokenType.begin: 'begin',
  TokenType.end: 'end',
  TokenType.read: 'read',
  TokenType.write: 'write',
  TokenType.eofScan: '\$',
};

/// Reserved keyword table for scanning grammar definition files.
const Map<TokenType, String> grammarReservedTokens = {
  TokenType.intLiteral: 'IntLiteral',
  TokenType.plusOp: 'PlusOp',
  TokenType.minusOp: 'MinusOp',
  TokenType.begin: 'begin',
  TokenType.end: 'end',
  TokenType.read: 'Read',
  TokenType.write: 'Write',
  TokenType.eofScan: '\$',
};

/// A table-driven lexical scanner.
///
/// Walks the source one character at a time through the [scannerTable] state
/// machine to produce a stream of [Token]s. Skipped lexemes (whitespace and
/// `--` comments) are recognized and discarded. A lexical miss is returned as
/// a `Left(LexicalFailure)`, never thrown.
final class Scanner {
  final String _source;
  final Map<TokenType, String> _reserved;

  int _index = 0;
  String _currentChar = ' ';
  String _nextChar = ' ';
  String _buffer = '';

  /// Creates a scanner over [source] using [reserved] keyword spellings.
  Scanner(String source, [Map<TokenType, String>? reserved])
    : _source = source,
      _reserved = reserved ?? programReservedTokens {
    // Seed one character ahead so the first consumeChar() leaves _currentChar
    // as a virtual leading space and _nextChar holding the first real char.
    _consumeChar();
  }

  /// Reads the next code unit into [_nextChar], returning [_eofChar] past the
  /// end of [_source].
  String _readChar() {
    if (_index >= _source.length) return _eofChar;
    return _source[_index++];
  }

  void _consumeChar() {
    _currentChar = _nextChar;
    _nextChar = _readChar();
  }

  /// Looks up the transition for [ch] in [state], mapping end-of-input to a
  /// newline (as the original stream `null` did).
  Either<LexicalFailure, Transition> _lookupState(int state, String ch) {
    final spec = scannerTable[state];
    if (spec == null) {
      return Left(LexicalFailure('[Scanner] Invalid state $state'));
    }
    final effective = ch == _eofChar ? '\n' : ch;
    final transition = spec.lookup(effective);
    if (transition == null) {
      return Left(
        LexicalFailure(
          "[Scanner] Cannot find character '$ch' for state '$state'",
        ),
      );
    }
    return Right(transition);
  }

  /// Resolves the reserved keyword for [_buffer], if any.
  TokenType? _reservedType(String buffer) {
    for (final entry in _reserved.entries) {
      if (entry.value == buffer) return entry.key;
    }
    return null;
  }

  /// Reads a single [Token].
  ///
  /// Skips whitespace and comments, recognizes reserved keywords, and returns
  /// the next meaningful token. Returns `EofSym` when the source is exhausted
  /// and a `Left(LexicalFailure)` when a character cannot be transitioned.
  Either<LexicalFailure, Token> scan() {
    _buffer = '';
    var state = 0;
    while (true) {
      final look = _lookupState(state, _currentChar);
      if (look.isLeft()) {
        return Left<LexicalFailure, Token>(look.getLeft().toNullable()!);
      }
      final transition = look.getRight().toNullable()!;

      switch (transition.action) {
        case ScanAction.error:
          return Left(
            LexicalFailure('[Scanner] Could not parse "$_currentChar".'),
          );

        case ScanAction.moveAppend:
          state = transition.state;
          _buffer += _currentChar;
          _consumeChar();

        case ScanAction.moveNoAppend:
          state = transition.state;
          _consumeChar();

        case ScanAction.haltAppend:
          _buffer += _currentChar;
          final emitted = _emit(transition.state, _buffer);
          _consumeChar();
          if (emitted != null) return Right(emitted);
          state = 0;

        case ScanAction.haltNoAppend:
        case ScanAction.haltReuse:
          final emitted = _emit(transition.state, _buffer);
          if (transition.action == ScanAction.haltNoAppend) _consumeChar();
          if (emitted != null) return Right(emitted);
          state = 0;
      }

      // The original loop's do-while exit: stop once the source is exhausted
      // and nothing is buffered.
      if (_currentChar == _eofChar && _buffer.isEmpty) break;
    }
    return Right(const Token(TokenType.eof, 'EofSym'));
  }

  /// Decides whether the accepting [state] with accumulated [buffer] produces
  /// a token. Returns `null` when the lexeme is skipped (whitespace/comment)
  /// and scanning must continue.
  Token? _emit(int state, String buffer) {
    final spec = scannerTable[state];
    final reserved = _reservedType(buffer);
    if (reserved != null) return Token(reserved, buffer);
    if (spec != null && spec.type != null && !spec.skip) {
      return Token(spec.type!, buffer);
    }
    return null;
  }

  /// Scans the whole source and joins every token name with a space, ending
  /// with `EofSym` — the same listing the original `scannerRun.js` printed.
  ///
  /// Throws nothing; the stop condition swallows any `Left` from an unskippable
  /// char so the shape of the listing always matches the original.
  Either<LexicalFailure, String> tokensAsString() {
    final names = <String>[];
    while (true) {
      final look = scan();
      if (look.isLeft()) {
        return Left<LexicalFailure, String>(look.getLeft().toNullable()!);
      }
      final token = look.getRight().toNullable()!;
      if (token.type == TokenType.eof) break;
      names.add(token.type.name);
    }
    return Right('${names.join(' ')} EofSym');
  }
}
