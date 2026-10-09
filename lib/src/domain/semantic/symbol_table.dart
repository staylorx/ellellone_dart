/// A symbol table recording which identifiers have been declared.
///
/// Handles lookup and insertion in declaration order. The original Node
/// version bounded the table at 1024 slots and threw on overflow; that fixed
/// bound was a 2016 artifact, so this port is unbounded and `enter` always
/// succeeds (declared in AGENTS.md).
final class SymbolTable {
  final Set<String> _symbols = <String>{};

  /// Returns true when [symbol] has been entered.
  bool lookup(String symbol) => _symbols.contains(symbol);

  /// Records [symbol], preserving declaration order. A duplicate is ignored.
  void enter(String symbol) {
    _symbols.add(symbol);
  }

  /// The number of distinct symbols entered.
  int get length => _symbols.length;

  /// The symbols in declaration order.
  List<String> get symbols => List.unmodifiable(_symbols);
}
