# ellellone

An **LL(1) compiler toolkit** reconstructed in Dart from the 2016 Node/ES6
source of `staylorx/ellellone-node` (a CU "Universal Compiler" class project
that demonstrated LL(1) parsing). It ships a table-driven lexical scanner, a
grammar engine (First/Follow/predict sets → LL(1) parse table), a predictive
LL(1) parser, and the semantic machinery behind them, plus a small CLI.

See [AGENTS.md](AGENTS.md) for how this repo is built (it declares deviations
from and wiring to the taybiz/dart-flutter-bible).

## Quick start

```sh
dart pub get
dart run bin/ellellone.dart scan 'begin A := BB + 314 + A; end $'
dart run bin/ellellone.dart grammar example/grammar2.txt
dart run bin/ellellone.dart parse example/grammar2.txt example/program.txt
dart run bin/ellellone.dart compile example/grammar2.txt example/program.txt
```

- `scan <source-or-file>` — tokenize a program and print its token stream.
- `grammar <grammar-file>` — load a grammar and print productions + parse table.
- `parse <grammar-file> <source-or-file>` — predictively parse a program and
  print the LL(1) trace.
- `compile <grammar-file> <source-or-file>` — run the semantic actions and
  print the generated three-address code (`Declare`, `ADD`/`SUB`, `Store`,
  `Read`, `Write`, `Halt`).

A grammar-file argument is a path; a program argument is a path if it names an
existing file, otherwise it is treated as inline source.

Custom keywords (e.g. a language using `START`/`STOP` instead of
`begin`/`end`) can be supplied with a reserved-token dictionary file via the
global `--reserved <file>` flag — one `kindName = lexeme` line per keyword
(`example/reserved_lang.txt`):

```sh
dart run bin/ellellone.dart --reserved example/reserved_lang.txt \
  scan 'START A := 1 + A; STOP $'
```

## Tests

```sh
dart test
```

The suite covers the scanner's tokenization, the grammar's parse table
(asserted against the original Node output), the LL(1) driver's trace, the
semantic support structures, and an architecture gate (`dart_arch_test`) that
enforces the package's layer direction and cycle-freedom.

## What's here

- `lib/` — the library, laid out as clean-architecture rings: `src/domain/`
  (pure entities and logic: `Token`, `Grammar`, `CompileFailure`,
  `ParseResult`, the semantic structures), `src/contracts/` (the `Scanner`,
  `GrammarLoader`, `Parser`, `CodeGenerator` ports), `src/usecases/`
  (`ScanUsecase`, `ParseUsecase`, `CompileUsecase`), and `src/adapters/`
  (`TableScanner`, `TextGrammarLoader`, `PredictiveLlParser`,
  `SemanticCodeGenerator`).
- `bin/ellellone.dart` — the command-line interface and composition root, which
  injects the adapters (scanner into parser and code generator, then into their
  usecases).
- `example/` — the grammar files it ships with and a demo program.
- `test/` — unit, integration, and architecture tests.
