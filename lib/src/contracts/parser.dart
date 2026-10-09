import 'package:fpdart/fpdart.dart';

import '../domain/failures/compile_failure.dart';
import '../domain/result/parse_result.dart';

/// The parsing port.
///
/// Runs the predictive parser over a program source, returning the LL(1) trace
/// or a [CompileFailure] as a value. The concrete parser is constructed with
/// its injected [Scanner] and [Grammar]; the source is the per-call parameter.
abstract interface class Parser {
  /// Parses [source], returning the trace or a [CompileFailure].
  Either<CompileFailure, ParseResult> parse(String source);
}
