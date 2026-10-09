import 'package:ellellone/ellellone.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

import 'support/example.dart';

/// Compiles a grammar fixture against a program through the usecase seam and
/// returns the joined three-address code listing.
String compileWith(String grammarName, String source) {
  final grammar = TextGrammarLoader().load(loadExample(grammarName));
  final result = CompileUsecase(
    SemanticCodeGenerator(TableScanner(), grammar),
  ).call(source);
  result.isRight().should.be(true);
  return result.getRight().toNullable()!.join('\n');
}

void main() {
  group('Given the demo program against grammar2', () {
    test('Then it emits the expected three-address code', () {
      compileWith('grammar2.txt', demoProgram).should.be(
        'Declare A,Integer\n'
        'Declare BB,Integer\n'
        'Declare Temp&1,Integer\n'
        'ADD 314,A,Temp&1\n'
        'Declare Temp&2,Integer\n'
        'ADD BB,Temp&1,Temp&2\n'
        'Store Temp&2,A\n'
        'Halt',
      );
    });
  });

  group('Given parenthesised and mixed operators', () {
    test('Then it binds parentheses and emits into temps', () {
      compileWith('grammar2.txt', 'begin A := (B - C) + D; end \$').should.be(
        'Declare A,Integer\n'
        'Declare B,Integer\n'
        'Declare C,Integer\n'
        'Declare Temp&1,Integer\n'
        'SUB B,C,Temp&1\n'
        'Declare D,Integer\n'
        'Declare Temp&2,Integer\n'
        'ADD Temp&1,D,Temp&2\n'
        'Store Temp&2,A\n'
        'Halt',
      );
    });
  });

  group('Given read and write statements', () {
    test('Then it emits Read/Declare per id and Write per expression', () {
      compileWith(
        'grammar2.txt',
        'begin read(A,B,C); Q := A + B + C; write(Q); end \$',
      ).should.be(
        'Declare A,Integer\n'
        'Read A,Integer\n'
        'Declare B,Integer\n'
        'Read B,Integer\n'
        'Declare C,Integer\n'
        'Read C,Integer\n'
        'Declare Q,Integer\n'
        'Declare Temp&1,Integer\n'
        'ADD B,C,Temp&1\n'
        'Declare Temp&2,Integer\n'
        'ADD A,Temp&1,Temp&2\n'
        'Store Temp&2,Q\n'
        'Write Q,Integer\n'
        'Halt',
      );
    });
  });
}
