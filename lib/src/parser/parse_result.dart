import 'package:equatable/equatable.dart';

/// The outcome of a successful predictive parse: the table-driven trace rows
/// the driver produced while matching the input.
final class ParseResult extends Equatable {
  /// Traces rows, header first, ending with a `Done` row.
  final List<String> trace;

  /// Creates a parse result carrying the given [trace] rows.
  const ParseResult(this.trace);

  @override
  List<Object?> get props => [trace];
}
