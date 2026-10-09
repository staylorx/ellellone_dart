# BACKLOG

Terse, actionable queue for this repo. No decisions, no metanarrative.

## Open

- **Wire grammar `#Action` symbols into executable 3-address codegen**
  (`generate` verb). The `Semantic` routines are present and tested; the
  LL(1) driver currently pops `#Action` symbols without firing them (faithful
  to the original's TODO). Closing = coding change: the attribute/evaluation
  scheme needs a written spec first — the original's action arities are
  inconsistent with its routine signatures (`#GenInfix($$, $1, $2, $$)`
  vs `genInfix(e1, op, e2)`), so behavior cannot be derived from the source.

- **Configurable reserved-word dictionary.** `programReservedTokens` /
  `grammarReservedTokens` are compile-time constants in
  `lib/src/scanner/scanner.dart`; all tests use them or a tiny inline override.
  Not yet user-facing. (Tiny; do only if a grammar needs it.)
