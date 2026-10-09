# BACKLOG

Terse, actionable queue for this repo. No decisions, no metanarrative.

## Open

(none — see Resolved.)

## Resolved

- **Wire grammar `#Action` symbols into executable three-address codegen.**
  **RESOLVED 2026-10-08:** `SemanticCodeGenerator` (adapters) now executes the
  `#Action` symbols during an LL(1) parse and emits three-address code
  (`Declare`, `ADD`/`SUB`, `Store`, `Read`, `Write`, `Halt`) through the
  `Semantic` routines, exposed as `CompileUsecase` and the `compile` CLI verb.
  Verified by `test/compile_test.dart` against hand-computed listings.

- **Configurable reserved-word dictionary.** **RESOLVED 2026-10-08:**
  `parseReservedTokens` (adapters) parses a `kindName = lexeme` dictionary file
  and the global `--reserved <file>` CLI flag injects it into the program
  scanner, so a language's keywords are configurable without editing Dart.
  Verified by `test/reserved_tokens_test.dart` and `example/reserved_lang.txt`.
