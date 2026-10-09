/// A single grammar production `lhs -> rhs`, where `rhs` carries the parseable
/// symbols and `rhsActions` additionally interleaves the semantic `#Action`
/// symbols that [Grammar] consumes to build the parse table.
final class Production {
  /// The 1-based production number.
  final int number;

  /// The left-hand-side nonterminal.
  final String lhs;

  /// The right-hand-side parseable symbols.
  final List<String> rhs;

  /// The right-hand side including interleaved semantic `#Action` symbols.
  final List<String> rhsActions;

  /// The terminals this production can predict.
  Set<String> predictSet;

  /// Creates a production with the given fields.
  Production({
    required this.number,
    required this.lhs,
    required this.rhs,
    required this.rhsActions,
    Set<String>? predictSet,
  }) : predictSet = predictSet ?? <String>{};

  @override
  String toString() => '$number: $lhs -> ${rhsActions.join(' ')}';
}
