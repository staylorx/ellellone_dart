# AGENTS.md — ellellone

An LL(1) compiler toolkit, reconstructed in Dart from the 2016 Node original
(`staylorx/ellellone-node`) as a single-package, CLI-only repo shaped as clean
architecture.

**Doctrine:** build to the taybiz/dart-flutter-bible
(clone: `C:/awork_local/mine/dart-flutter-bible`; ingest blob:
`docs/00-compact.md`). This file carries only what deviates from or wires that
doctrine — it never restates the rules.

## Error style (declared)

Consumers receive **FP-style tuples**: lexical and syntax failures are
`Either<CompileFailure, T>` values from fpdart, never thrown. The CLI (`bin/`)
is the only ring that formats a failure and exits non-zero.

**One declared exception:** a malformed grammar *definition* raises
[`GrammarFailure`] from a [`GrammarLoader`] (`TextGrammarLoader` in
`lib/src/adapters/`). A grammar file is a tooling input; its syntax errors are
treated like a bad config schema and surfaced loudly at load time, distinct
from the *program* under compilation, whose lexical/syntactic errors are
carried as values.

## Shape (clean architecture, single package)

`lib/src/` is organised into rings with a `dart_arch_test` onion gate keeping
dependencies pointing inward, plus cycle-freedom and the no-`src`-imports-barrel
(front-door) rule (`test/architecture_test.dart`):

- **`domain/`** — pure entities and set-building logic, no IO and no scanner
  dependency: `Token`, `TokenType`, `CompileFailure`, `Production`,
  `ParseResult`, the semantic structures, and `Grammar` (which builds
  First/Follow/predict sets and the parse table from a `List<Production>`,
  classifying `<...>` symbols as nonterminals).
- **`contracts/`** — the ports: `Scanner`, `GrammarLoader`, `Parser`.
- **`usecases/`** — the application facades: `ScanUsecase`, `ParseUsecase`,
  each depending only on a contract.
- **`adapters/`** — the concrete implementations: `TableScanner`,
  `TextGrammarLoader`, `PredictiveLlParser`.

The CLI (`bin/`) is the **composition root**: it constructs the adapters and
injects them — scanner into parser, parser into the parse usecase. A future
`CodeGenerator` contract + `CompileUsecase` slot into the same pattern when the
semantic-action BACKLOG item lands.

## Deviations from the bible (tracked, see BACKLOG for open ones)

- **Single package, no melos/workspace** (bible topology A: one-delivery CLI).
  The rings are directories, not separate packages; this keeps the three tools
  in one delivery and the arch gate is the hard boundary.
- **No repository/persistence ring.** A compiler has no datasource; the only
  real IO is file reading in the CLI. The bible's ≥2-repository-adapter rule
  targets persistence and does not apply.
- **`SymbolTable` is unbounded.** The original capped it at 1024 slots and
  threw on overflow; that fixed bound was a 2016 artifact and was dropped
  (`lib/src/domain/semantic/symbol_table.dart`).
- **Semantic `#Action` execution is stubbed.** The parser driver pops grammar
  `#Action` symbols without firing them, exactly as the original's driver did
  (its TODO). The semantic layer — `Semantic`, `SemanticStack`, `SymbolTable`,
  and the records — is present, coherent, and unit-tested as the ready seam.
  Wiring the actions into executable 3-address codegen is an open BACKLOG item.
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
