import 'package:fpdart/fpdart.dart';

import '../contracts/scanner.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/tokens/token.dart';

/// Application facade for the **scan** tool.
///
/// Depends only on the [Scanner] contract, which the composition root injects
/// with the concrete lexer. Thin by design — the bible's application layer is
/// the seam served by the CLI.
final class ScanUsecase {
  final Scanner _scanner;

  /// Wraps the injected [Scanner] as the scan seam.
  ScanUsecase(this._scanner);

  /// Tokenizes [source], returning the token list or a [LexicalFailure].
  Either<LexicalFailure, List<Token>> call(String source) =>
      _scanner.scan(source);
}
