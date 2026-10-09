/// ellellone — an LL(1) compiler toolkit reconstructed in Dart.
///
/// Provides a table-driven lexical [Scanner], a [Grammar] engine that builds
/// First/Follow/predict sets and an LL(1) parse table, a predictive
/// [LlParser], and the semantic machinery ([SemanticStack], [SymbolTable],
/// [Semantic]) behind a `bin/ellellone` command-line interface.
///
/// **Error style:** consumers receive FP-style tuples. Lexical, syntax and
/// grammar failures are carried as a value — `Either<CompileFailure, T>` from
/// fpdart — never thrown. The CLI is the only ring that formats a failure and
/// exits. One declared exception: a malformed grammar *definition* raises
/// [GrammarFailure] at [Grammar] construction, treating a bad grammar file as
/// a tooling error.
///
/// Symbols are the scanner's symbolic token names: `<program>` for
/// nonterminals, `Id` for terminals, and `λ` for the empty production, all
/// matching the original Node implementation.
library;

export 'src/failures/compile_failure.dart';
export 'src/grammar/grammar.dart';
export 'src/grammar/production.dart';
export 'src/parser/parser.dart';
export 'src/parser/parse_result.dart';
export 'src/scanner/scanner.dart';
export 'src/scanner/scanner_table.dart';
export 'src/semantic/records.dart';
export 'src/semantic/semantic.dart';
export 'src/semantic/semantic_stack.dart';
export 'src/semantic/symbol_table.dart';
export 'src/tokens/token.dart';
export 'src/tokens/token_type.dart';
