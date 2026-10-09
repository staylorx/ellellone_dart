import 'package:fpdart/fpdart.dart';

import '../contracts/parser.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/result/parse_result.dart';

/// Application facade for the **parse** tool.
///
/// Depends only on the [Parser] contract, which the composition root injects
/// (the parser itself holds the injected [Scanner] and grammar). Thin by
/// design — the application layer is the seam served by the CLI.
final class ParseUsecase {
  final Parser _parser;

  /// Wraps the injected [Parser] as the parse seam.
  ParseUsecase(this._parser);

  /// Parses [source], returning the trace or a [CompileFailure].
  Either<CompileFailure, ParseResult> call(String source) =>
      _parser.parse(source);
}
