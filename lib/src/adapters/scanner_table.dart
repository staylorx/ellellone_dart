import '../domain/tokens/token_type.dart';

/// The movement actions a transition can request, mirroring the original
/// Node scanner's bit-coded action table.
enum ScanAction {
  /// Consume the character, advance the state.
  moveAppend,

  /// Move state without appending to the token buffer.
  moveNoAppend,

  /// Halt: emit the token and append the current character to it.
  haltAppend,

  /// Halt: emit the token without appending the current character.
  haltNoAppend,

  /// Halt: emit the token and reuse the current character for the next token.
  haltReuse,

  /// Fail: cannot transition on this character.
  error,
}

/// A single table transition: the next state and the action to take.
final class Transition {
  /// The next scanner state after this transition.
  final int state;

  /// The action to take when this transition fires.
  final ScanAction action;

  /// Creates a transition to [state] with the given [action].
  const Transition(this.state, this.action);
}

/// One row of the scanner state table.
///
/// Transient states (mid-lookahead) have no [type]; accepting states carry the
/// [TokenType] they emit plus whether the emitted lexeme is skipped
/// (whitespace and comments are produced but discarded).
final class StateSpec {
  /// The token emitted by this accepting state, or null when it is transient.
  final TokenType? type;

  /// Whether the emitted lexeme is discarded rather than returned.
  final bool skip;

  /// The ordered character-group transitions.
  final List<MapEntry<String, Transition>> transitions;

  /// The fallback transition when no character group matches.
  final Transition? other;

  /// Creates a state specification with the given fields.
  const StateSpec({
    this.type,
    this.skip = false,
    this.transitions = const [],
    this.other,
  });

  /// Finds the transition for [ch] by scanning the character groups in order,
  /// falling back to [other] when present.
  Transition? lookup(String ch) {
    for (final entry in transitions) {
      if (entry.key.contains(ch)) return entry.value;
    }
    return other;
  }
}

// Character classes shared by several state rows.
const String _letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
const String _lettersDollar = '\$$_letters';
const String _digits = '0123456789';
const String _lambda = 'λ';

/// The bootstrap state table for the scanner, ported verbatim from
/// `ellellone-node/app/scanner.js`. State numbers and transitions are
/// preserved so tokenization matches the original exactly.
final Map<int, StateSpec> scannerTable = <int, StateSpec>{
  0: StateSpec(
    transitions: [
      MapEntry(_lettersDollar, const Transition(1, ScanAction.moveAppend)),
      MapEntry(_digits, const Transition(2, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('+', const Transition(14, ScanAction.haltAppend)),
      MapEntry('-', const Transition(4, ScanAction.moveAppend)),
      MapEntry(':', const Transition(6, ScanAction.moveAppend)),
      MapEntry(',', const Transition(17, ScanAction.haltAppend)),
      MapEntry(';', const Transition(18, ScanAction.haltAppend)),
      MapEntry('(', const Transition(19, ScanAction.haltAppend)),
      MapEntry(')', const Transition(20, ScanAction.haltAppend)),
      MapEntry('\t', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('\r', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('\n', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('<', const Transition(7, ScanAction.moveAppend)),
      MapEntry('>', const Transition(7, ScanAction.moveAppend)),
      MapEntry('#', const Transition(8, ScanAction.moveAppend)),
      MapEntry(_lambda, const Transition(24, ScanAction.haltNoAppend)),
    ],
  ),
  1: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(1, ScanAction.moveAppend)),
      MapEntry(_digits, const Transition(1, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(11, ScanAction.haltNoAppend)),
      MapEntry('+', const Transition(11, ScanAction.haltReuse)),
      MapEntry('-', const Transition(11, ScanAction.haltReuse)),
      MapEntry('=', const Transition(11, ScanAction.haltReuse)),
      MapEntry(':', const Transition(11, ScanAction.haltReuse)),
      MapEntry(',', const Transition(11, ScanAction.haltReuse)),
      MapEntry(';', const Transition(11, ScanAction.haltReuse)),
      MapEntry('(', const Transition(11, ScanAction.haltReuse)),
      MapEntry(')', const Transition(11, ScanAction.haltReuse)),
      MapEntry('_', const Transition(1, ScanAction.moveAppend)),
      MapEntry('\t', const Transition(11, ScanAction.haltNoAppend)),
      MapEntry('\r', const Transition(11, ScanAction.haltNoAppend)),
      MapEntry('\n', const Transition(11, ScanAction.haltNoAppend)),
    ],
  ),
  2: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(12, ScanAction.haltReuse)),
      MapEntry(_digits, const Transition(2, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(12, ScanAction.haltNoAppend)),
      MapEntry('+', const Transition(12, ScanAction.haltReuse)),
      MapEntry('-', const Transition(12, ScanAction.haltReuse)),
      MapEntry('=', const Transition(12, ScanAction.haltReuse)),
      MapEntry(':', const Transition(12, ScanAction.haltReuse)),
      MapEntry(',', const Transition(12, ScanAction.haltReuse)),
      MapEntry(';', const Transition(12, ScanAction.haltReuse)),
      MapEntry('(', const Transition(12, ScanAction.haltReuse)),
      MapEntry(')', const Transition(12, ScanAction.haltReuse)),
      MapEntry('_', const Transition(12, ScanAction.haltReuse)),
      MapEntry('\t', const Transition(12, ScanAction.haltNoAppend)),
      MapEntry('\r', const Transition(12, ScanAction.haltNoAppend)),
      MapEntry('\n', const Transition(12, ScanAction.haltNoAppend)),
    ],
  ),
  3: StateSpec(
    type: TokenType.emptySpace,
    skip: true,
    transitions: [
      MapEntry(_lettersDollar, const Transition(13, ScanAction.haltReuse)),
      MapEntry(_digits, const Transition(13, ScanAction.haltReuse)),
      MapEntry(' ', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('+', const Transition(13, ScanAction.haltReuse)),
      MapEntry('-', const Transition(13, ScanAction.haltReuse)),
      MapEntry('=', const Transition(13, ScanAction.haltReuse)),
      MapEntry(':', const Transition(13, ScanAction.haltReuse)),
      MapEntry(',', const Transition(13, ScanAction.haltReuse)),
      MapEntry(_lambda, const Transition(24, ScanAction.haltNoAppend)),
      MapEntry(';', const Transition(13, ScanAction.haltReuse)),
      MapEntry('(', const Transition(13, ScanAction.haltReuse)),
      MapEntry(')', const Transition(13, ScanAction.haltReuse)),
      MapEntry('_', const Transition(13, ScanAction.haltReuse)),
      MapEntry('\t', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('\r', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('\n', const Transition(3, ScanAction.moveNoAppend)),
      MapEntry('#', const Transition(8, ScanAction.moveAppend)),
      MapEntry('<', const Transition(13, ScanAction.haltReuse)),
    ],
  ),
  4: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(21, ScanAction.haltReuse)),
      MapEntry(_digits, const Transition(21, ScanAction.haltReuse)),
      MapEntry(' ', const Transition(21, ScanAction.haltNoAppend)),
      MapEntry('+', const Transition(21, ScanAction.haltReuse)),
      MapEntry('-', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('=', const Transition(21, ScanAction.haltReuse)),
      MapEntry(':', const Transition(21, ScanAction.haltReuse)),
      MapEntry(',', const Transition(21, ScanAction.haltReuse)),
      MapEntry(';', const Transition(21, ScanAction.haltReuse)),
      MapEntry('(', const Transition(21, ScanAction.haltReuse)),
      MapEntry(')', const Transition(21, ScanAction.haltReuse)),
      MapEntry('\r', const Transition(21, ScanAction.haltNoAppend)),
      MapEntry('\n', const Transition(21, ScanAction.haltNoAppend)),
      MapEntry('>', const Transition(23, ScanAction.haltNoAppend)),
    ],
  ),
  5: StateSpec(
    type: TokenType.comment,
    skip: true,
    other: const Transition(5, ScanAction.moveNoAppend),
    transitions: [
      MapEntry(_letters, const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(_digits, const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(' ', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('+', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('-', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('=', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(':', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(',', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(';', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('(', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry(')', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('_', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('\t', const Transition(5, ScanAction.moveNoAppend)),
      MapEntry('\r', const Transition(15, ScanAction.haltNoAppend)),
      MapEntry('\n', const Transition(15, ScanAction.haltNoAppend)),
    ],
  ),
  6: StateSpec(
    transitions: [MapEntry('=', const Transition(16, ScanAction.haltAppend))],
  ),
  7: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(7, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(7, ScanAction.moveAppend)),
      MapEntry('>', const Transition(22, ScanAction.haltAppend)),
    ],
  ),
  8: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(8, ScanAction.moveAppend)),
      MapEntry(_digits, const Transition(8, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(25, ScanAction.haltNoAppend)),
      MapEntry('(', const Transition(9, ScanAction.moveAppend)),
    ],
  ),
  9: StateSpec(
    transitions: [
      MapEntry(_letters, const Transition(9, ScanAction.moveAppend)),
      MapEntry(_digits, const Transition(9, ScanAction.moveAppend)),
      MapEntry(' ', const Transition(9, ScanAction.moveAppend)),
      MapEntry('\$', const Transition(9, ScanAction.moveAppend)),
      MapEntry(',', const Transition(9, ScanAction.moveAppend)),
      MapEntry(')', const Transition(25, ScanAction.haltAppend)),
    ],
  ),
  11: const StateSpec(type: TokenType.id),
  12: const StateSpec(type: TokenType.intLiteral),
  13: const StateSpec(type: TokenType.emptySpace, skip: true),
  14: const StateSpec(type: TokenType.plusOp),
  15: const StateSpec(type: TokenType.comment, skip: true),
  16: const StateSpec(type: TokenType.assignOp),
  17: const StateSpec(type: TokenType.comma),
  18: const StateSpec(type: TokenType.semiColon),
  19: const StateSpec(type: TokenType.lParen),
  20: const StateSpec(type: TokenType.rParen),
  21: const StateSpec(type: TokenType.minusOp),
  22: const StateSpec(type: TokenType.nonTerminal),
  23: const StateSpec(type: TokenType.produces),
  24: const StateSpec(type: TokenType.lambda),
  25: const StateSpec(type: TokenType.action),
};
