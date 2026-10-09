import 'package:equatable/equatable.dart';

/// What an [ExpressionRecord] holds.
enum ExpressionKind {
  /// A named identifier value.
  id,

  /// An integer literal value.
  literal,

  /// A compiler-generated temporary value.
  temp,
}

/// A binary arithmetic operator.
enum OperatorKind {
  /// The addition operator.
  plus,

  /// The subtraction operator.
  minus,
}

/// Which payload a [SemanticRecord] carries.
enum SemanticRecordKind {
  /// A binary operator payload.
  operator,

  /// An expression payload.
  expression,

  /// An error payload.
  error,
}

/// A binary operator attribute (`+` -> ADD, `-` -> SUB).
final class OperatorRecord extends Equatable {
  /// The operator kind this record carries.
  final OperatorKind kind;

  /// Creates an operator record of [kind].
  const OperatorRecord(this.kind);

  @override
  List<Object?> get props => [kind];
}

/// A value attribute: an identifier, an integer literal, or a temporary.
final class ExpressionRecord extends Equatable {
  /// The kind of value this expression record holds.
  final ExpressionKind kind;

  /// The identifier or temporary name; empty for a literal.
  final String name;

  /// The integer literal value, or null for non-literals.
  final int? value;

  /// Creates an identifier expression record for [name].
  const ExpressionRecord.id(this.name) : kind = ExpressionKind.id, value = null;

  /// Creates a temporary expression record for [name].
  const ExpressionRecord.temp(this.name)
    : kind = ExpressionKind.temp,
      value = null;

  /// Creates an integer literal expression record with [value].
  const ExpressionRecord.literal(int this.value)
    : kind = ExpressionKind.literal,
      name = '';

  @override
  List<Object?> get props => [kind, name, value];
}

/// A stack attribute during semantic processing, wrapping exactly one payload.
final class SemanticRecord extends Equatable {
  /// Which payload this record carries.
  final SemanticRecordKind kind;

  /// The operator payload, when kind is operator.
  final OperatorRecord? operator;

  /// The expression payload, when kind is expression.
  final ExpressionRecord? expression;

  /// The error payload, when kind is error.
  final String? error;

  /// Creates a record wrapping [operator].
  const SemanticRecord.operator(OperatorRecord this.operator)
    : kind = SemanticRecordKind.operator,
      expression = null,
      error = null;

  /// Creates a record wrapping [expression].
  const SemanticRecord.expression(ExpressionRecord this.expression)
    : kind = SemanticRecordKind.expression,
      operator = null,
      error = null;

  /// Creates a record wrapping [error].
  const SemanticRecord.error(String this.error)
    : kind = SemanticRecordKind.error,
      operator = null,
      expression = null;

  @override
  List<Object?> get props => [kind, operator, expression, error];
}
