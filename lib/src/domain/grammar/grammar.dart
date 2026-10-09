import 'production.dart';

/// The epsilon marker used across the First/Follow/predict machinery, kept
/// identical to the original Node grammar (`'Lambda'`).
const String lambdaMarker = 'Lambda';

/// Default start symbol whose FOLLOW set seeds the end-of-input marker.
const String defaultStartSymbol = '<system goal>';

/// A pure LL(1) grammar: the production list plus the First, Follow, predict
/// and parse-table sets derived from it.
///
/// This is domain logic with no IO and no scanner dependency. The grammar text
/// is turned into [Production]s by a `GrammarLoader` adapter; the loader sees
/// the symbolic token names this grammar reasons over. A nonterminal is any
/// `<...>` symbol (how the scanner classifies `<program>`), everything else on
/// a right-hand side is a terminal.
final class Grammar {
  final List<Production> _productions;

  /// The grammar's nonterminal symbols.
  final Set<String> nonTerminals = <String>{};

  /// The grammar's terminal symbols.
  final Set<String> terminals = <String>{};

  final Map<String, bool> _derivesLambda = <String, bool>{};
  final Map<String, Set<String>> _first = <String, Set<String>>{};
  final Map<String, Set<String>> _follow = <String, Set<String>>{};

  /// parseTable[nonterminal][terminal] = production number to predict.
  final Map<String, Map<String, int>> parseTable = <String, Map<String, int>>{};

  /// Builds the grammar and its parse table from [productions].
  Grammar(List<Production> productions) : _productions = List.of(productions) {
    _collectVocabulary();
    fillParseTable();
  }

  /// The productions in definition order (1-indexed by [Production.number]).
  List<Production> get productions => List.unmodifiable(_productions);

  /// FIRST sets per symbol.
  Map<String, Set<String>> get firstSets => _first;

  /// FOLLOW sets per nonterminal.
  Map<String, Set<String>> get followSets => _follow;

  /// Separates the vocabulary: `<...>` symbols are nonterminals, the rest of
  /// the right-hand sides are terminals.
  void _collectVocabulary() {
    for (final p in _productions) {
      nonTerminals.add(p.lhs);
      for (final s in p.rhs) {
        if (s.startsWith('<')) {
          nonTerminals.add(s);
        } else {
          terminals.add(s);
        }
      }
    }
  }

  /// Marks which symbols can derive the empty string.
  void _markLambda() {
    for (final s in nonTerminals) {
      _derivesLambda[s] = false;
    }
    for (final t in terminals) {
      _derivesLambda[t] = false;
    }
    var changed = true;
    while (changed) {
      changed = false;
      for (final p in _productions) {
        final allNullable = p.rhs.every(
          (s) => s == lambdaMarker || _derivesLambda[s] == true,
        );
        if (allNullable && !(_derivesLambda[p.lhs] ?? false)) {
          _derivesLambda[p.lhs] = true;
          changed = true;
        }
      }
    }
  }

  /// Fills FIRST for every symbol to a fixpoint.
  void _fillFirst() {
    _markLambda();
    for (final t in terminals) {
      _first[t] = <String>{t};
    }
    for (final a in nonTerminals) {
      _first[a] = _derivesLambda[a] == true
          ? <String>{lambdaMarker}
          : <String>{};
    }
    // Ensure a bare 'Lambda' terminal (the epsilon production) has FIRST {Λ}.
    _first.putIfAbsent(lambdaMarker, () => <String>{lambdaMarker});

    var changed = true;
    while (changed) {
      changed = false;
      for (final p in _productions) {
        final unioned = _computeFirst(p.rhs);
        final before = _first[p.lhs]!;
        final grew = unioned.any((e) => !before.contains(e));
        if (grew) {
          _first[p.lhs]!.addAll(unioned);
          changed = true;
        }
      }
    }
  }

  /// FIRST of a symbol sequence: the terminals a string can begin with,
  /// plus Λ when the whole sequence is nullable.
  Set<String> _computeFirst(List<String> seq) {
    if (seq.isEmpty) return <String>{lambdaMarker};
    final result = <String>{};
    for (var i = 0; i < seq.length; i++) {
      final sym = seq[i];
      if (sym == lambdaMarker) break;
      final f = _first[sym] ?? <String>{};
      result.addAll(f.where((e) => e != lambdaMarker));
      if (!f.contains(lambdaMarker)) return result;
    }
    if (seq.every(
      (s) => s == lambdaMarker || _first[s]!.contains(lambdaMarker),
    )) {
      result.add(lambdaMarker);
    }
    return result;
  }

  /// Fills FOLLOW for every nonterminal to a fixpoint.
  void _fillFollow() {
    _fillFirst();
    final start = defaultStartSymbol;
    for (final a in nonTerminals) {
      _follow[a] = <String>{};
    }
    // The start symbol's FOLLOW seeds the end-of-input marker (Λ stands in
    // for `$` here, matching the original).
    (_follow[start] ??= <String>{}).add(lambdaMarker);

    var changed = true;
    while (changed) {
      changed = false;
      for (final p in _productions) {
        final lhsFollow = _follow[p.lhs]!;
        for (var j = 0; j < p.rhs.length; j++) {
          final b = p.rhs[j];
          if (!nonTerminals.contains(b)) continue;
          final firstBeta = _computeFirst(p.rhs.sublist(j + 1));
          final followB = _follow[b]!;
          final before = Set<String>.of(followB);
          followB.addAll(firstBeta.where((e) => e != lambdaMarker));
          if (firstBeta.contains(lambdaMarker)) followB.addAll(lhsFollow);
          if (!_same(before, followB)) changed = true;
        }
      }
    }
  }

  /// Computes predict sets and assembles the parse table.
  void fillParseTable() {
    _fillFollow();
    for (final p in _productions) {
      final firstHead = _first[p.rhs.isEmpty ? '' : p.rhs.first] ?? <String>{};
      if (firstHead.contains(lambdaMarker) || firstHead.isEmpty) {
        final follow = _follow[p.lhs] ?? <String>{};
        p.predictSet = follow.where((e) => e != lambdaMarker).toSet();
      } else {
        p.predictSet = Set<String>.of(firstHead);
      }
    }
    for (final nt in nonTerminals) {
      final row = <String, int>{};
      for (final p in _productions) {
        if (p.lhs == nt) {
          for (final t in p.predictSet) {
            row[t] = p.number;
          }
        }
      }
      parseTable[nt] = row;
    }
  }

  /// The production number to predict for stack top [x] and lookahead [a], or
  /// `null` when none exists (a syntax error in the driver).
  int? t(String x, String a) => parseTable[x]?[a];

  static bool _same(Set<String> a, Set<String> b) =>
      a.length == b.length && a.every(b.contains);
}
