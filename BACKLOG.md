# BACKLOG

Terse, actionable queue for this repo. No decisions, no metanarrative.

## Open

- **Configurable reserved-word dictionary.** `programReservedTokens` /
  `grammarReservedTokens` are compile-time constants in
  `lib/src/adapters/`; all tests use them or a tiny inline override.
  Not yet user-facing. (Tiny; do only if a grammar needs it.)

## Resolved

- **Wire grammar `#Action` symbols into executable three-address codegen.**
  **RESOLVED 2026-10-08:** `SemanticCodeGenerator` (adapters) now executes the
  `#Action` symbols during an LL(1) parse and emits three-address code
  (`Declare`, `ADD`/`SUB`, `Store`, `Read`, `Write`, `Halt`) through the
  `Semantic` routines, exposed as `CompileUsecase` and the `compile` CLI verb.
  Verified by `test/compile_test.dart` against hand-computed listings.
