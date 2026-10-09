import 'package:fpdart/fpdart.dart';

import '../contracts/scanner.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/tokens/token.dart';
import '../domain/tokens/token_type.dart';
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

/// The concrete state-machine lexer ([Scanner] adapter).
///
/// Walks [source] one character at a time through the [scannerTable] state
/// machine and returns the full token list. The reserved-vocabulary is fixed
/// at construction (default: [programReservedTokens]).
final class TableScanner implements Scanner {
  final Map<TokenType, String> _reserved;

  /// Creates the lexer, optionally overriding the reserved vocabulary.
  TableScanner({Map<TokenType, String>? reserved})
    : _reserved = reserved ?? programReservedTokens;

  @override
  Either<LexicalFailure, List<Token>> scan(String source) {
    final lexer = _Lexer(source, _reserved);
    final tokens = <Token>[];
    while (true) {
      final one = lexer.one();
      if (one.isLeft()) {
        return Left<LexicalFailure, List<Token>>(one.getLeft().toNullable()!);
      }
      final token = one.getRight().toNullable()!;
      if (token.type == TokenType.eof) break;
      tokens.add(token);
    }
    return Right(tokens);
  }
}

/// The per-source character reader behind [TableScanner].
final class _Lexer {
  final String _source;
  final Map<TokenType, String> _reserved;

  int _index = 0;
  String _currentChar = ' ';
  String _nextChar = ' ';
  String _buffer = '';

  _Lexer(this._source, this._reserved) {
    // Seed one character ahead so the first consumeChar() leaves _currentChar
    // as a virtual leading space and _nextChar holding the first real char.
    _consumeChar();
  }

  String _readChar() {
    if (_index >= _source.length) return _eofChar;
    return _source[_index++];
  }

  void _consumeChar() {
    _currentChar = _nextChar;
    _nextChar = _readChar();
  }

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

  TokenType? _reservedType(String buffer) {
    for (final entry in _reserved.entries) {
      if (entry.value == buffer) return entry.key;
    }
    return null;
  }

  /// Reads the next single [Token], skipping whitespace and comments.
  Either<LexicalFailure, Token> one() {
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
          _buffer = '';
          state = 0;

        case ScanAction.haltNoAppend:
        case ScanAction.haltReuse:
          final emitted = _emit(transition.state, _buffer);
          if (transition.action == ScanAction.haltNoAppend) _consumeChar();
          if (emitted != null) return Right(emitted);
          _buffer = '';
          state = 0;
      }

      // The original loop's do-while exit: stop once the source is exhausted
      // and nothing is buffered.
      if (_currentChar == _eofChar && _buffer.isEmpty) break;
    }
    return Right(const Token(TokenType.eof, 'EofSym'));
  }

  Token? _emit(int state, String buffer) {
    final spec = scannerTable[state];
    final reserved = _reservedType(buffer);
    if (reserved != null) return Token(reserved, buffer);
    if (spec != null && spec.type != null && !spec.skip) {
      return Token(spec.type!, buffer);
    }
    return null;
  }
}
