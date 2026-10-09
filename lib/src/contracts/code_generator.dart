import 'package:fpdart/fpdart.dart';

import '../domain/failures/compile_failure.dart';

/// The code-generation port.
///
/// Turns a program source into a three-address code listing — `Declare`,
/// `Store`, `Read`, `Write`, `ADD`/`SUB`, `Halt` — or a [CompileFailure] as a
/// value. A generator is configured with an injected [Scanner] and [Grammar];
/// the source is the per-call parameter.
abstract interface class CodeGenerator {
  /// Compiles [source] into a three-address code listing.
  Either<CompileFailure, List<String>> generate(String source);
}
