import 'package:fpdart/fpdart.dart';

import '../failures/compile_failure.dart';
import '../grammar/grammar.dart';
import '../grammar/production.dart';
import '../scanner/scanner.dart';
import '../semantic/semantic_stack.dart';
import '../tokens/token_type.dart';
import 'parse_result.dart';

/// Marker placed on the parse stack to bound a production's semantic region.
const String _eopMarker = '<\$eop>';

/// The predictive LL(1) parser driver.
///
/// Maintains a parse stack alongside the [Grammar]'s parse table: a nonterminal
/// on top is expanded by predicting a production from the current lookahead
/// token; a terminal is matched against it; an EOP marker or an `#Action`
/// symbol is popped. Semantic `#Action` symbols are recognised and popped
/// (exactly as the original Node driver left them), so the trace is faithful
/// to the source while the [SemanticStack] is still maintained for the
/// semantic routines.
final class LlParser {
  final Grammar _grammar;
  final Scanner _scanner;
  final SemanticStack _semanticStack;

  TokenType _current = TokenType.id;
  TokenType _next = TokenType.id;
  final List<String> _parseStack = [];
  final List<String> _trace = [];

  /// Creates an LL(1) driver running the given grammar over the given scanner.
  LlParser(this._grammar, this._scanner) : _semanticStack = SemanticStack();

  /// Runs the LL(1) driver over the scanner's token stream.
  ///
  /// Returns the trace table on success or a [SyntaxFailure]/[LexicalFailure]
  /// on the first mismatch. Failures are values; nothing is thrown for a bad
  /// program.
  Either<CompileFailure, ParseResult> parse() {
    _parseStack.clear();
    _trace.clear();
    _parseStack.add(grammarStartSymbol);
    // Two primes mirror the original: the constructor's scanFeed() plus the
    // driver's own scanFeed(), so `_current` holds the first token and `_next`
    // the second when the loop starts.
    final prime = _scanFeed();
    if (prime.isLeft()) {
      return Left<CompileFailure, ParseResult>(prime.getLeft().toNullable()!);
    }
    final primed = _scanFeed();
    if (primed.isLeft()) {
      return Left<CompileFailure, ParseResult>(primed.getLeft().toNullable()!);
    }

    _trace.add('|${_pad('PREDICT', 11)}|${_pad('TOKEN', 24)}|PARSE STACK');

    while (_parseStack.isNotEmpty) {
      final x = _parseStack.first;
      final a = _current.name;

      if (_grammar.nonTerminals.contains(x)) {
        _trace.add(
          '|${_pad('Predict ${_grammar.t(x, a)}', 11)}'
          '|${_pad('$a ${_next.name} ...', 24)}'
          '|${_parseStack.join(' ')}',
        );
        final predicted = _grammar.t(x, a);
        if (predicted == null) {
          return Left(
            SyntaxFailure(
              '[Parser] No production for $x on token $a (T($x,$a) is undefined).',
            ),
          );
        }
        final production = _productionFor(predicted);
        _parseStack.removeAt(0);
        final reversed = production.rhsActions.contains(lambdaMarker)
            ? <String>[]
            : production.rhsActions.reversed.toList();
        for (final y in reversed) {
          _parseStack.insert(0, y);
        }
        _semanticStack.pushEop(production.rhsActions);
        _parseStack.insert(0, _eopMarker);
      } else if (_grammar.terminals.contains(x)) {
        if (x == a) {
          _trace.add(
            '|${_pad('Match', 11)}'
            '|${_pad('$a ${_next.name} ...', 24)}'
            '|${_parseStack.join(' ')}',
          );
          _parseStack.removeAt(0);
          final fed = _scanFeed();
          if (fed.isLeft()) {
            return Left<CompileFailure, ParseResult>(
              fed.getLeft().toNullable()!,
            );
          }
        } else {
          return Left(
            SyntaxFailure('[Parser] Expected terminal $x but saw $a.'),
          );
        }
      } else if (x == _eopMarker) {
        _semanticStack.popEop();
        _parseStack.removeAt(0);
      } else if (x.startsWith('#')) {
        // The original driver recognises and pops #Action symbols without
        // firing the semantic routine. Kept faithful here; the routines live
        // in the semantic layer and are wired as a BACKLOG item.
        _parseStack.removeAt(0);
      } else {
        return Left(SyntaxFailure('[Parser] Unexpected stack symbol "$x".'));
      }
    }

    _trace.add(
      '|${_pad('Done', 11)}|${_pad(' ', 24)}|${_parseStack.join(' ')}',
    );
    return Right(ParseResult(List.unmodifiable(_trace)));
  }

  /// Advances the two-token lookahead window; surfaces a lexical failure when
  /// the scanner cannot classify the next character.
  Either<CompileFailure, TokenType> _scanFeed() {
    final token = _scanner.scan();
    if (token.isLeft()) {
      return Left<CompileFailure, TokenType>(token.getLeft().toNullable()!);
    }
    _current = _next;
    _next = token.getRight().toNullable()!.type;
    return Right(_next);
  }

  Production _productionFor(int number) =>
      _grammar.productions.firstWhere((p) => p.number == number);

  static String _pad(String s, int len) {
    if (s.length >= len) return s;
    return s + ' ' * (len - s.length);
  }
}

/// The grammar's start symbol, matching the original's default.
const String grammarStartSymbol = defaultStartSymbol;
