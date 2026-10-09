import 'dart:io';

import 'package:args/args.dart';
import 'package:ellellone/ellellone.dart';
import 'package:fpdart/fpdart.dart';

/// The `ellellone` command-line interface.
///
/// Verbs:
///
/// - `scan <source-or-file>` — tokenize a program and print its token stream.
/// - `grammar <grammar-file>` — load a grammar and print its parse table.
/// - `parse <grammar-file> <source-or-file>` — predictively parse a program
///   against a grammar and print the LL(1) trace.
///
/// This is the UI ring: it is the only place that formats a [CompileFailure]
/// and exits non-zero. Nothing in `lib/` prints or exits.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('scan')
    ..addCommand('grammar')
    ..addCommand('parse');

  final result = parser.parse(arguments);
  final command = result.command?.name;
  if (command == null) {
    stderr.writeln('usage: ellellone <scan|grammar|parse> ...');
    exitCode = 64;
    return;
  }

  switch (command) {
    case 'scan':
      _scan(result.command!);
    case 'grammar':
      _grammar(result.command!);
    case 'parse':
      _parse(result.command!);
  }
}

void _scan(ArgResults arguments) {
  final source = _sourceOf(arguments.rest);
  if (source == null) {
    stderr.writeln('usage: ellellone scan <source-or-file>');
    exitCode = 64;
    return;
  }
  final scanner = Scanner(source);
  switch (scanner.tokensAsString()) {
    case Left(value: final failure):
      stderr.writeln('scan error: ${failure.message}');
      exitCode = 65;
    case Right(value: final tokens):
      stdout.writeln(tokens);
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
    grammar = Grammar(file.readAsStringSync());
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

void _parse(ArgResults arguments) {
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
    grammar = Grammar(file.readAsStringSync());
  } on GrammarFailure catch (e) {
    stderr.writeln('grammar error: $e');
    exitCode = 65;
    return;
  }
  final source = _sourceOf(arguments.rest.sublist(1));
  final parser = LlParser(grammar, Scanner(source!));
  switch (parser.parse()) {
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
