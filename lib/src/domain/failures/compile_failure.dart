import 'package:equatable/equatable.dart';

/// Root of the compiler's failure hierarchy.
///
/// Failure is carried as a value (fpdart `Either<CompileFailure, T>`, per the
/// dart-flutter-bible) rather than thrown. The CLI is the only ring that
/// formats a failure and exits; libraries never raise for a compile error.
sealed class CompileFailure extends Equatable {
  /// The human-readable description of the failure.
  final String message;

  const CompileFailure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// A character could not be transitioned in the scanner state table.
final class LexicalFailure extends CompileFailure {
  /// Creates a lexical failure with [message].
  const LexicalFailure(super.message);
}

/// The predictive parser reached a token it could not shift or expand.
final class SyntaxFailure extends CompileFailure {
  /// Creates a syntax failure with [message].
  const SyntaxFailure(super.message);
}

/// A grammar definition file itself is malformed (e.g. the second token of a
/// production is not `->`).
final class GrammarFailure extends CompileFailure {
  /// Creates a grammar failure with [message].
  const GrammarFailure(super.message);
}
