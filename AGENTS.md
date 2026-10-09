# AGENTS.md — ellellone

An LL(1) compiler toolkit, reconstructed in Dart from the 2016 Node original
(`staylorx/ellellone-node`) as a single-package, CLI-only repo.

**Doctrine:** build to the taybiz/dart-flutter-bible
(clone: `C:/awork_local/mine/dart-flutter-bible`; ingest blob:
`docs/00-compact.md`). This file carries only what deviates from or wires that
doctrine — it never restates the rules.

## Error style (declared)

Consumers receive **FP-style tuples**: lexical, syntax, and grammar failures are
`Either<CompileFailure, T>` values from fpdart, never thrown. The CLI (`bin/`)
is the only ring that formats a failure and exits non-zero.

**One declared exception:** a malformed grammar *definition* raises
[`GrammarFailure`] at [`Grammar`] construction (`lib/src/grammar/grammar.dart`).
A grammar file is a tooling input; its syntax errors are treated like a bad
config schema and surfaced loudly at build time, distinct from the *program*
under compilation, whose lexical/syntactic errors are carried as values.

## Deviations from the bible (tracked, see BACKLOG for open ones)

- **Not a CRUD clean-architecture app.** This is a compiler pipeline, so there
  is no usecase/repository/datasource ring and no multi-repository-adapter rule.
  The onion/hard boundary gate instead enforces the parsing areas under
  `lib/src/`: `tokens` innermost → `semantic` → `scanner` → `grammar` →
  `parser` outermost, plus cycle-freedom and the no-`src`-imports-barrel
  (front-door) rule. That gate is a real `dart_arch_test` test
  (`test/architecture_test.dart`).
- **Single package, no melos/workspace** (bible topology A: one-delivery CLI).
- **`SymbolTable` is unbounded.** The original capped it at 1024 slots and
  threw on overflow; that fixed bound was a 2016 artifact and was dropped
  (`lib/src/semantic/symbol_table.dart`).
- **Semantic `#Action` execution is stubbed.** The LL(1) driver (`LlParser`)
  recognises and pops grammar `#Action` symbols without firing them, exactly as
  the original's driver did (its TODO). The semantic layer — `Semantic`,
  `SemanticStack`, `SymbolTable`, and the records — is present, coherent, and
  unit-tested as the ready seam. Wiring the actions into executable 3-address
  codegen is an open BACKLOG item.
- **Grammar reader appends a trailing space per production line** so a trailing
  `#Action` symbol is emitted. The original's files carried trailing whitespace
  for exactly this reason (the scanner's Action state has no end-of-line
  transition).

## Local wiring

- Package `ellellone`; executable `ellellone`. Toolchain: Dart via fvm
  (`C:/Users/stayl/fvm/default/bin/dart`) — not on PATH in this shell.
- CLI verbs: `scan <source-or-file>`, `grammar <grammar-file>`,
  `parse <grammar-file> <source-or-file>`.
- Sample inputs live in `example/` (grammar1/2/blocks + a demo program); tests
  read them via `test/support/example.dart`.
- Gate: `dart analyze --fatal-infos --fatal-warnings` (zero diagnostics of any
  severity) + `dart test` (includes the architecture gate). `dart format .`.

## Working agreement (user standing rule)

Direct-to-main: commit and push once green (HTTPS+PAT per the `github` skill);
never leave finished work parked locally.
