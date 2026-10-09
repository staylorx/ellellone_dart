import 'package:ellellone/ellellone.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

import 'support/example.dart';

/// Parses a grammar fixture against a program through the usecase seam.
Either<CompileFailure, ParseResult> parseWith(
  String grammarName,
  String source,
) {
  final grammar = TextGrammarLoader().load(loadExample(grammarName));
  final parser = PredictiveLlParser(TableScanner(), grammar);
  return ParseUsecase(parser).call(source);
}

void main() {
  group('Given the demo program against grammar2', () {
    test('Then it parses successfully with the ground-truth trace rows', () {
      final result = parseWith('grammar2.txt', demoProgram);
      result.isRight().should.be(true);
      final trace = result.getRight().toNullable()!.trace;
      trace.first.contains('PREDICT').should.be(true);
      trace
          .any(
            (row) =>
                row.contains('Predict 23') && row.contains('<system goal>'),
          )
          .should
          .be(true);
      // The driver runs to completion.
      trace.last.contains('Done').should.be(true);
    });
  });

  group('Given a program with a syntax error', () {
    test('Then it returns a syntax failure (missing semicolon)', () {
      final result = parseWith('grammar1.txt', 'begin A := BB end \$');
      result.isLeft().should.be(true);
      result.getLeft().toNullable()!.should.beOfType<SyntaxFailure>();
    });
  });

  group('Given an empty program', () {
    test('Then it returns a failure rather than throwing', () {
      final result = parseWith('grammar1.txt', '');
      result.isLeft().should.be(true);
    });
  });
}
