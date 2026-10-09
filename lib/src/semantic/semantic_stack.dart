/// Snapshot of the semantic stack's pointers taken when a production is
/// expanded, used to restore them when the production's EOP marker is popped.
class _EopRecord {
  final int left;
  final int right;
  final int current;
  final int top;

  const _EopRecord(this.left, this.right, this.current, this.top);
}

/// The attributed semantic stack used to hold symbol values during a parse.
///
/// Four pointers (`left`, `right`, `current`, `top`) bound the region of the
/// stack that belongs to the innermost production. [pushEop] opens a new
/// region (returning nothing here; the parser tracks its own end-of-production
/// marker), [pushToken] records a matched terminal's value, and [popEop]
/// restores the pointers when the region closes. Ported from the original
/// `semanticStack.js`.
final class SemanticStack {
  final List<String> _stack;
  final List<_EopRecord> _history = [];
  int _left;
  int _right;
  int _current;
  int _top;

  /// Creates an empty semantic stack seeded with [startSymbol].
  SemanticStack([String startSymbol = '<system goal>'])
    : _stack = List.of(<String>[startSymbol]),
      _left = 0,
      _right = 0,
      _current = 1,
      _top = 2;

  /// The value under the `current` pointer.
  String currentItem() => _stack[_current - 1];

  /// Records a matched terminal's value at the current position.
  ///
  /// The stack grows on demand: the original JavaScript array grew on index
  /// assignment, which Dart lists do not do.
  void pushToken(String token) {
    while (_stack.length <= _current) {
      _stack.add('');
    }
    _stack[_current] = token;
    _current++;
  }

  /// Unshifts the production's right-hand symbols onto the stack and opens a
  /// semantic region over them.
  void pushEop(List<String> symbols) {
    _history.add(_EopRecord(_left, _right, _current, _top));
    _stack.insertAll(0, symbols);
    _left = _current;
    _right = _top;
    _current = _right;
    _top += symbols.length;
  }

  /// Restores the pointers recorded when the region was opened.
  void popEop() {
    final last = _history.removeLast();
    _left = last.left;
    _right = last.right;
    _current = last.current;
    _top = last.top;
  }
}
