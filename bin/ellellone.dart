import 'dart:io';

import 'package:args/args.dart';
import 'package:ellellone/ellellone.dart';
import 'package:fpdart/fpdart.dart';

/// The `ellellone` command-line interface — the composition root.
///
/// Verbs:
///
/// - `scan <source-or-file>` — tokenize a program and print its token stream.
/// - `grammar <grammar-file>` — load a grammar and print its parse table.
/// - `parse <grammar-file> <source-or-file>` — predictively parse a program
///   against a grammar and print the LL(1) trace.
/// - `compile <grammar-file> <source-or-file>` — emit three-address code.
///
/// `--reserved <file>` (global) overrides the program's reserved-keyword
/// spellings with a `kindName = lexeme` dictionary (see [parseReservedTokens]).
///
/// This is the UI ring: the only place that wires adapters into usecases,
/// formats a [CompileFailure] and exits non-zero. Nothing in `lib/` prints or
/// exits.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'reserved',
      abbr: 'r',
      help:
          'file of kindName = lexeme reserved-token pairs (overrides the '
          'built-in program keyword spellings)',
    )
    ..addCommand('scan')
    ..addCommand('grammar')
    ..addCommand('parse')
    ..addCommand('compile');

  final result = parser.parse(arguments);
  final command = result.command?.name;
  if (command == null) {
    stderr.writeln(
      'usage: ellellone [--reserved file] <scan|grammar|parse|compile> ...',
    );
    exitCode = 64;
    return;
  }

  final reserved = _reservedDict(result['reserved'] as String?);
  if (result['reserved'] != null && reserved == null) return;

  switch (command) {
    case 'scan':
      _scan(result.command!, reserved);
    case 'grammar':
      _grammar(result.command!);
    case 'parse':
      _parse(result.command!, reserved);
    case 'compile':
      _compile(result.command!, reserved);
  }
}

/// Loads and parses the `--reserved` dictionary file, reporting an error
/// itself. Returns `null` when no file was given or when loading failed.
Map<TokenType, String>? _reservedDict(String? path) {
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('reserved dictionary file not found: $path');
    exitCode = 66;
    return null;
  }
  try {
    return parseReservedTokens(file.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('reserved dictionary error: ${e.message}');
    exitCode = 65;
    return null;
  }
}

void _scan(ArgResults arguments, Map<TokenType, String>? reserved) {
  final source = _sourceOf(arguments.rest);
  if (source == null) {
    stderr.writeln('usage: ellellone scan <source-or-file>');
    exitCode = 64;
    return;
  }
  final scan = ScanUsecase(TableScanner(reserved: reserved));
  switch (scan.call(source)) {
    case Left(value: final failure):
      stderr.writeln('scan error: ${failure.message}');
      exitCode = 65;
    case Right(value: final tokens):
      stdout.writeln('${tokens.map((t) => t.type.name).join(' ')} EofSym');
  }
}

void _grammar(ArgResults arguments) {
  final path = arguments.rest.length == 1 ? arguments.rest.first : null;
  if (path == null) {
    stderr.writeln('usage: ellellone grammar <grammar-file>');
    exitCode = 64;
    return;
  }
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('grammar file not found: $path');
    exitCode = 66;
    return;
  }
  final Grammar grammar;
  try {
    grammar = TextGrammarLoader().load(file.readAsStringSync());
  } on GrammarFailure catch (e) {
    stderr.writeln('grammar error: $e');
    exitCode = 65;
    return;
  }
  stdout
    ..writeln('Productions:')
    ..writeln(grammar.productions.map((p) => '  $p').join('\n'))
    ..writeln('Terminals: ${grammar.terminals.join(' ')}')
    ..writeln('Nonterminals: ${grammar.nonTerminals.join(' ')}')
    ..writeln('Parse table (nonterminal, lookahead -> production):');
  for (final nt in grammar.nonTerminals) {
    final row = grammar.parseTable[nt]!;
    if (row.isEmpty) continue;
    stdout.writeln('  $nt');
    for (final entry in row.entries) {
      stdout.writeln('    ${entry.key} -> ${entry.value}');
    }
  }
}

void _parse(ArgResults arguments, Map<TokenType, String>? reserved) {
  if (arguments.rest.length < 2) {
    stderr.writeln('usage: ellellone parse <grammar-file> <source-or-file>');
    exitCode = 64;
    return;
  }
  final file = File(arguments.rest[0]);
  if (!file.existsSync()) {
    stderr.writeln('grammar file not found: ${arguments.rest[0]}');
    exitCode = 66;
    return;
  }
  final Grammar grammar;
  try {
    grammar = TextGrammarLoader().load(file.readAsStringSync());
  } on GrammarFailure catch (e) {
    stderr.writeln('grammar error: $e');
    exitCode = 65;
    return;
  }
  final source = _sourceOf(arguments.rest.sublist(1));

  // Composition root: scanner injected into parser, parser into the usecase.
  final parser = PredictiveLlParser(TableScanner(reserved: reserved), grammar);
  final parse = ParseUsecase(parser);
  switch (parse.call(source!)) {
    case Left(value: final failure):
      stderr.writeln('parse error: ${failure.message}');
      exitCode = 65;
    case Right(value: final result):
      for (final row in result.trace) {
        stdout.writeln(row);
      }
  }
}

/// Returns the single positional argument treated as a file path that exists,
/// or as inline source text.
String? _sourceOf(List<String> rest) {
  if (rest.length != 1) return null;
  final arg = rest.first;
  final file = File(arg);
  if (file.existsSync()) return file.readAsStringSync();
  return arg;
}

void _compile(ArgResults arguments, Map<TokenType, String>? reserved) {
  if (arguments.rest.length < 2) {
    stderr.writeln('usage: ellellone compile <grammar-file> <source-or-file>');
    exitCode = 64;
    return;
  }
  final file = File(arguments.rest[0]);
  if (!file.existsSync()) {
    stderr.writeln('grammar file not found: ${arguments.rest[0]}');
    exitCode = 66;
    return;
  }
  final Grammar grammar;
  try {
    grammar = TextGrammarLoader().load(file.readAsStringSync());
  } on GrammarFailure catch (e) {
    stderr.writeln('grammar error: $e');
    exitCode = 65;
    return;
  }
  final source = _sourceOf(arguments.rest.sublist(1));

  // Composition root: scanner + grammar injected into the code generator,
  // generator into the compile usecase.
  final generator = SemanticCodeGenerator(
    TableScanner(reserved: reserved),
    grammar,
  );
  final compile = CompileUsecase(generator);
  switch (compile.call(source!)) {
    case Left(value: final failure):
      stderr.writeln('compile error: ${failure.message}');
      exitCode = 65;
    case Right(value: final code):
      for (final line in code) {
        stdout.writeln(line);
      }
  }
}
