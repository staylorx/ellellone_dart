import 'package:equatable/equatable.dart';

import 'token_type.dart';

/// A single lexeme produced by the scanner.
///
/// [type] is the symbolic token kind and [lexeme] is the source text that was
/// read for it (for punctuation it is the punctuation itself; for an
/// identifier it is the identifier text). Tokens are value objects: two
/// tokens are equal when their kind and lexeme are equal.
final class Token extends Equatable {
  /// The symbolic kind of the token.
  final TokenType type;

  /// The source text read for the token.
  final String lexeme;

  /// Creates a token of [type] with the given [lexeme].
  const Token(this.type, this.lexeme);

  @override
  List<Object?> get props => [type, lexeme];

  @override
  String toString() => '${type.name}($lexeme)';
}
