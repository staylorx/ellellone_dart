import '../contracts/grammar_loader.dart';
import '../contracts/scanner.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/grammar/grammar.dart';
import '../domain/grammar/production.dart';
import '../domain/tokens/token.dart';
import '../domain/tokens/token_type.dart';
import 'table_scanner.dart';

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

/// Reads a grammar-definition text into a pure [Grammar] ([GrammarLoader]
/// adapter).
///
/// Each non-blank line is scanned (with a grammar-vocabulary scanner) into one
/// [Production], then handed to the [Grammar] domain object. A malformed
/// definition raises [GrammarFailure] — the declared case where a grammar
/// error surfaces as an exception rather than a value.
final class TextGrammarLoader implements GrammarLoader {
  final Scanner _scanner;

  /// Creates the loader; [scanner] defaults to a grammar-vocabulary lexer.
  TextGrammarLoader([Scanner? scanner])
    : _scanner = scanner ?? TableScanner(reserved: grammarReservedTokens);

  @override
  Grammar load(String source) {
    final productions = <Production>[];
    var number = 1;
    for (final line in source.split('\n')) {
      if (line.trim().isEmpty) continue;
      // Append a terminator so a trailing `#Action` symbol is emitted: the
      // Action state has no end-of-line transition, and the original files
      // carried a trailing space for exactly this reason.
      final scan = _scanner.scan('$line ');
      if (scan.isLeft()) {
        throw GrammarFailure(
          '[Grammar] Could not read production "$line": '
          '${scan.getLeft().toNullable()!.message}',
        );
      }
      final tokens = scan.getRight().toNullable()!;
      if (tokens.length < 2) {
        throw GrammarFailure('[Grammar] Malformed production "$line".');
      }
      var i = 0;
      Token next() => tokens[i++];

      final lhs = next();
      if (lhs.type != TokenType.nonTerminal) {
        throw GrammarFailure(
          '[Grammar] Expected a nonterminal LHS, found "${lhs.type.name}"',
        );
      }
      final produces = next();
      if (produces.type != TokenType.produces) {
        throw GrammarFailure("The second token should be '->'");
      }

      final rhArray = <String>[];
      final rhActions = <String>[];
      while (i < tokens.length) {
        final t = next();
        switch (t.type) {
          case TokenType.nonTerminal:
            rhArray.add(t.lexeme);
            rhActions.add(t.lexeme);
          case TokenType.action:
            rhActions.add(t.lexeme);
          default:
            rhArray.add(t.type.name);
            rhActions.add(t.type.name);
        }
      }
      productions.add(
        Production(
          number: number++,
          lhs: lhs.lexeme,
          rhs: rhArray,
          rhsActions: rhActions,
        ),
      );
    }
    return Grammar(productions);
  }
}
