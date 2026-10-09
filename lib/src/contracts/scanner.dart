import 'package:fpdart/fpdart.dart';

import '../domain/failures/compile_failure.dart';
import '../domain/tokens/token.dart';

/// The lexical-analysis port.
///
/// Turns a program source into the full token list, excluding the end-of-input
/// sentinel, or a [LexicalFailure] as a value (never thrown). A scanner may be
/// configured for a vocabulary (program vs grammar keywords); the configured
/// vocabulary is fixed at construction.
abstract interface class Scanner {
  /// Lexes [source] into the token list (excluding the end-of-input sentinel).
  Either<LexicalFailure, List<Token>> scan(String source);
}
