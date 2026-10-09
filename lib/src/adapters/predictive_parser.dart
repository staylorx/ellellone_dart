import 'package:fpdart/fpdart.dart';

import '../contracts/parser.dart';
import '../contracts/scanner.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/grammar/grammar.dart';
import '../domain/grammar/production.dart';
import '../domain/result/parse_result.dart';
import '../domain/semantic/semantic_stack.dart';
import '../domain/tokens/token.dart';
import '../domain/tokens/token_type.dart';

/// Marker placed on the parse stack to bound a production's semantic region.
const String _eopMarker = '<\$eop>';

/// The concrete predictive LL(1) parser ([Parser] adapter).
///
/// The [Scanner] and [Grammar] are injected at construction (the composition
/// root passes the same lexer into the parser); [parse] takes the program
/// source as its business parameter, scans it, then drives the parse stack
/// alongside the grammar's parse table. Failures are values; nothing is thrown
/// for a bad program.
final class PredictiveLlParser implements Parser {
  final Scanner _scanner;
  final Grammar _grammar;

  /// Injects the [Scanner] and [Grammar] the driver parses against.
  PredictiveLlParser(this._scanner, this._grammar);

  @override
  Either<CompileFailure, ParseResult> parse(String source) {
    final scan = _scanner.scan(source);
    if (scan.isLeft()) {
      return Left<CompileFailure, ParseResult>(scan.getLeft().toNullable()!);
    }
    return _drive(scan.getRight().toNullable()!);
  }

  Either<CompileFailure, ParseResult> _drive(List<Token> tokens) {
    final semanticStack = SemanticStack();
    final parseStack = <String>[defaultStartSymbol];
    final trace = <String>[];
    var index = 0;

    TokenType fetch() {
      final t = index < tokens.length
          ? tokens[index++]
          : const Token(TokenType.eof, 'EofSym');
      return t.type;
    }

    // Two primes mirror the original: the constructor's scanFeed() plus the
    // driver's own scanFeed(), so `current` holds the first token and `next`
    // the second when the loop starts.
    var current = TokenType.id;
    var next = TokenType.id;
    void step() {
      current = next;
      next = fetch();
    }

    step();
    step();

    trace.add('|${_pad('PREDICT', 11)}|${_pad('TOKEN', 24)}|PARSE STACK');

    while (parseStack.isNotEmpty) {
      final x = parseStack.first;
      final a = current.name;

      if (_grammar.nonTerminals.contains(x)) {
        trace.add(
          '|${_pad('Predict ${_grammar.t(x, a)}', 11)}'
          '|${_pad('$a ${next.name} ...', 24)}'
          '|${parseStack.join(' ')}',
        );
        final predicted = _grammar.t(x, a);
        if (predicted == null) {
          return Left(
            SyntaxFailure(
              '[Parser] No production for $x on token $a '
              '(T($x,$a) is undefined).',
            ),
          );
        }
        final production = _productionFor(predicted);
        parseStack.removeAt(0);
        final reversed = production.rhsActions.contains(lambdaMarker)
            ? <String>[]
            : production.rhsActions.reversed.toList();
        for (final y in reversed) {
          parseStack.insert(0, y);
        }
        semanticStack.pushEop(production.rhsActions);
        parseStack.insert(0, _eopMarker);
      } else if (_grammar.terminals.contains(x)) {
        if (x == a) {
          trace.add(
            '|${_pad('Match', 11)}'
            '|${_pad('$a ${next.name} ...', 24)}'
            '|${parseStack.join(' ')}',
          );
          parseStack.removeAt(0);
          step();
        } else {
          return Left(
            SyntaxFailure('[Parser] Expected terminal $x but saw $a.'),
          );
        }
      } else if (x == _eopMarker) {
        semanticStack.popEop();
        parseStack.removeAt(0);
      } else if (x.startsWith('#')) {
        // The original driver recognises and pops #Action symbols without
        // firing the semantic routine. Kept faithful here; the routines live
        // in the semantic layer and are wired as a BACKLOG item.
        parseStack.removeAt(0);
      } else {
        return Left(SyntaxFailure('[Parser] Unexpected stack symbol "$x".'));
      }
    }

    trace.add('|${_pad('Done', 11)}|${_pad(' ', 24)}|${parseStack.join(' ')}');
    return Right(ParseResult(List.unmodifiable(trace)));
  }

  Production _productionFor(int number) =>
      _grammar.productions.firstWhere((p) => p.number == number);

  static String _pad(String s, int len) {
    if (s.length >= len) return s;
    return s + ' ' * (len - s.length);
  }
}
