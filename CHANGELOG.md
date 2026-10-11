# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Wire the grammar `#Action` symbols into executable three-address codegen.
  `SemanticCodeGenerator` executes the `#Action` symbols during an LL(1) parse
  and emits three-address code (`Declare`, `ADD`/`SUB`, `Store`, `Read`,
  `Write`, `Halt`) through the `Semantic` routines, exposed as
  `CompileUsecase` and the `compile` CLI verb. Covered by
  `test/compile_test.dart`.
- Configurable reserved-word dictionary. `parseReservedTokens` parses a
  `kindName = lexeme` dictionary file and the global `--reserved <file>` CLI
  flag injects it into the program scanner, so a language's keywords are
  configurable without editing Dart. Covered by `test/reserved_tokens_test.dart`
  and `example/reserved_lang.txt`.
