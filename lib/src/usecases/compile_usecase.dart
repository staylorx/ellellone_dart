import 'package:fpdart/fpdart.dart';

import '../contracts/code_generator.dart';
import '../domain/failures/compile_failure.dart';

/// Application facade for the **compile** tool.
///
/// Depends only on the [CodeGenerator] contract, which the composition root
/// injects (the generator itself holds the injected [Scanner] and [Grammar]).
/// Thin by design — the application layer is the seam served by the CLI.
final class CompileUsecase {
  final CodeGenerator _generator;

  /// Wraps the injected [CodeGenerator] as the compile seam.
  CompileUsecase(this._generator);

  /// Compiles [source] into three-address code lines or a [CompileFailure].
  Either<CompileFailure, List<String>> call(String source) =>
      _generator.generate(source);
}
