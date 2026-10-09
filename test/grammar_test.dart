import 'package:ellellone/ellellone.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

import 'support/example.dart';

void main() {
  group('Given grammar2', () {
    test('Then it records the full vocabulary and 23 productions', () {
      final g = Grammar(loadExample('grammar2.txt'));
      g.productions.length.should.be(23);
      g.nonTerminals.contains('<system goal>').should.be(true);
      g.nonTerminals.contains('<statement>').should.be(true);
      g.terminals.contains('Id').should.be(true);
      g.terminals.contains('BeginSym').should.be(true);
      g.terminals.contains('EndSym').should.be(true);
    });

    test(
      'Then the parse table predicts the ground-truth production numbers',
      () {
        final g = Grammar(loadExample('grammar2.txt'));
        // Spot-checked against the original parserRun.js trace.
        g.t('<system goal>', 'BeginSym').should.be(23);
        g.t('<program>', 'BeginSym').should.be(1);
        g.t('<statement>', 'Id').should.be(5);
        g.t('<statement>', 'ReadSym').should.be(6);
        g.t('<statement>', 'WriteSym').should.be(7);
        g.t('<statement tail>', 'EndSym').should.be(4);
        g.t('<ident>', 'Id').should.be(22);
        g.t('<expression>', 'Id').should.be(14);
        g.t('<primary>', 'Id').should.be(18);
        g.t('<primary>', 'IntLiteral').should.be(19);
        g.t('<primary>', 'LParen').should.be(17);
        g.t('<primary tail>', 'PlusOp').should.be(15);
        g.t('<primary tail>', 'SemiColon').should.be(16);
        g.t('<add op>', 'PlusOp').should.be(20);
        g.t('<add op>', 'MinusOp').should.be(21);
        // No production for this combo -> LL(1) syntax error.
        g.t('<system goal>', 'Id').should.beNull();
      },
    );

    test('Then FIRST and FOLLOW sets are populated', () {
      final g = Grammar(loadExample('grammar2.txt'));
      g.firstSets['Id']!.contains('Id').should.be(true);
      // <primary tail> can derive lambda, so ε is in its FIRST set.
      g.firstSets['<primary tail>']!.contains('Lambda').should.be(true);
      g.followSets['<statement tail>']!.contains('EndSym').should.be(true);
      g.followSets['<primary tail>']!.contains('SemiColon').should.be(true);
    });
  });

  group('Given a malformed production', () {
    test('Then constructing the grammar raises a GrammarFailure', () {
      Object? caught;
      try {
        Grammar('<program> begin <stmt list> end');
      } catch (e) {
        caught = e;
      }
      caught.should.beOfType<GrammarFailure>();
    });
  });
}
