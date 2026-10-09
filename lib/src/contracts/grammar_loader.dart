import '../domain/grammar/grammar.dart';

/// The grammar-loading port.
///
/// Produces a [Grammar] from grammar-definition text. Loaders are adapters at
/// the boundary: they may read a file or scan text, but the grammar object
/// they build is pure domain. A malformed definition raises [GrammarFailure];
/// this is the declared case where a compile-domain failure surfaces as an
/// exception (grammar definitions are tooling/config input).
abstract interface class GrammarLoader {
  /// Loads a [Grammar] from grammar-definition [source].
  Grammar load(String source);
}
