/// ellellone — an LL(1) compiler toolkit reconstructed in Dart.
///
/// Shaped as clean architecture split between independent tools that compose:
/// a [Scanner], a [GrammarLoader], a [Parser], and (once wired) a code
/// generator. The ring layout under `src/` is:
///
/// - `domain/` — pure entities and logic ([Token], [TokenType],
///   [CompileFailure], [Grammar], [ParseResult], the semantic structures).
/// - `contracts/` — the ports ([Scanner], [GrammarLoader], [Parser]) that
///   adapters implement and usecases depend on.
/// - `usecases/` — the application facades ([ScanUsecase], [ParseUsecase]),
///   injected with the contracts.
/// - `adapters/` — the concrete implementations ([TableScanner],
///   [TextGrammarLoader], [PredictiveLlParser]).
///
/// The CLI (`bin/`) is the composition root: it constructs the adapters and
/// injects them — scanner into parser, parser into the parse usecase.
///
/// **Error style:** consumers receive FP-style tuples. Lexical and syntax
/// failures are carried as a value — `Either<CompileFailure, T>` from fpdart —
/// never thrown. One declared exception: a malformed grammar *definition*
/// raises [GrammarFailure] from a [GrammarLoader], treating a bad grammar file
/// as a tooling error.
library;

export 'src/adapters/predictive_parser.dart';
export 'src/adapters/reserved_tokens.dart';
export 'src/adapters/scanner_table.dart';
export 'src/adapters/semantic_code_generator.dart';
export 'src/adapters/table_scanner.dart';
export 'src/adapters/text_grammar_loader.dart';
export 'src/contracts/code_generator.dart';
export 'src/contracts/grammar_loader.dart';
export 'src/contracts/parser.dart';
export 'src/contracts/scanner.dart';
export 'src/domain/failures/compile_failure.dart';
export 'src/domain/grammar/grammar.dart';
export 'src/domain/grammar/production.dart';
export 'src/domain/result/parse_result.dart';
export 'src/domain/semantic/records.dart';
export 'src/domain/semantic/semantic.dart';
export 'src/domain/semantic/semantic_stack.dart';
export 'src/domain/semantic/symbol_table.dart';
export 'src/domain/tokens/token.dart';
export 'src/domain/tokens/token_type.dart';
export 'src/usecases/compile_usecase.dart';
export 'src/usecases/parse_usecase.dart';
export 'src/usecases/scan_usecase.dart';
