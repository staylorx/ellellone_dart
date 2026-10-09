import 'package:ellellone/ellellone.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  group('Given a SemanticStack', () {
    test('Then pushToken grows the stack and EOP restores the pointers', () {
      final s = SemanticStack('<system goal>');
      s.currentItem().should.be('<system goal>');

      s.pushToken('Id');
      s.pushToken('AssignOp');
      s.currentItem().should.be('AssignOp');

      // Expanding a production opens a region; popping it restores the
      // pointers without throwing.
      s.pushEop(const ['<expression>', '#GenInfix(\$\$, \$1, \$2, \$\$)']);
      s.popEop();
      s.pushToken('Id');
      s.currentItem().should.be('Id');
    });
  });

  group('Given a SymbolTable', () {
    test('Then enter then lookup reports declared symbols once', () {
      final t = SymbolTable();
      t.lookup('A').should.be(false);
      t.enter('A');
      t.lookup('A').should.be(true);
      t.enter('A'); // duplicate ignored
      t.length.should.be(1);
    });
  });

  group('Given the Semantic code generator', () {
    test('Then generate builds instructions and records declarative lines', () {
      final sem = Semantic();
      sem.generate('Halt').should.be('Halt');
      sem.generate('Store', const ['x', 'y']).should.be('Store x,y');
      sem.checkId('X').should.be('Declare X,Integer');
      sem.checkId('X').should.be(''); // already declared
      sem.getTemp().should.be('Temp&1');
      sem.finish().should.be('Halt');
    });

    test('Then process* builds the right records', () {
      final sem = Semantic();
      final id = sem.processId('Y');
      id.kind.should.be(ExpressionKind.id);
      id.name.should.be('Y');
      final lit = sem.processLiteral(42);
      lit.kind.should.be(ExpressionKind.literal);
      lit.value.should.be(42);
      sem.processOp('PlusOp').kind.should.be(OperatorKind.plus);
      sem.processOp('MinusOp').kind.should.be(OperatorKind.minus);
    });
  });
}
