import 'package:ellellone/ellellone.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The token-stream listing the scanner must produce for a program, exact to
/// the original Node implementation.
String scanAll(String source) => TableScanner()
    .scan(source)
    .fold(
      (failure) => throw failure,
      (tokens) => '${tokens.map((t) => t.type.name).join(' ')} EofSym',
    );

/// Scans with an explicit reserved-keyword dictionary, mirroring how the
/// original tests configured the scanner per program.
String scanAllWith(String source, Map<TokenType, String> reserved) =>
    TableScanner(reserved: reserved)
        .scan(source)
        .fold(
          (failure) => throw failure,
          (tokens) => '${tokens.map((t) => t.type.name).join(' ')} EofSym',
        );

const Map<TokenType, String> upperReserved = {
  TokenType.begin: 'BEGIN',
  TokenType.end: 'END',
  TokenType.read: 'READ',
  TokenType.write: 'WRITE',
};

void main() {
  group('Given a simple assignment program', () {
    test('When scanned, then it yields the expected token stream', () {
      scanAll('begin A := BB + 314 + A; end \$').should.be(
        'BeginSym Id AssignOp Id PlusOp IntLiteral PlusOp Id SemiColon '
        'EndSym EOfScan EofSym',
      );
    });
  });

  group('Given the HW#2 parser input', () {
    test('When scanned, then it yields the expected token stream', () {
      scanAllWith('BEGIN A := B +(72 - C); END', upperReserved).should.be(
        'BeginSym Id AssignOp Id PlusOp LParen IntLiteral MinusOp Id '
        'RParen SemiColon EndSym EofSym',
      );
    });
  });

  group('Given a program with reads and writes', () {
    test('When scanned, then comments and spaces are skipped', () {
      scanAllWith('''
        BEGIN --SOMETHING NEW
          X:= 15;
          A:= 3141 + X - 75;
        END
        ''', upperReserved).should.be(
        'BeginSym Id AssignOp IntLiteral SemiColon Id AssignOp IntLiteral '
        'PlusOp Id MinusOp IntLiteral SemiColon EndSym EofSym',
      );
    });
  });

  group('Given a grammar production line', () {
    test('When scanned, then it tokenizes to production symbols', () {
      // Uses nonterminals, the `->` producer, keywords and the `$` end marker.
      scanAll(
        '<primary tail> -> λ',
      ).should.be('NonTerminal Produces Lambda EofSym');
    });

    test('When scanned, then a production with a terminal reads as one', () {
      // Grammar vocabulary reserves the capitalised `Read`, so it comes back
      // as ReadSym rather than a bare identifier.
      scanAllWith(
        '<primary tail>->Read(<expression>);',
        grammarReservedTokens,
      ).should.be(
        'NonTerminal Produces ReadSym LParen NonTerminal RParen SemiColon '
        'EofSym',
      );
    });
  });

  group('Given the HW#1 listing one', () {
    test('When scanned, then it yields the full original token stream', () {
      scanAllWith('''
        BEGIN --SOMETHING UNUSUAL
          READ(A1, New_A, D, B);
          C:= A1 +(New_A - D) - 75;
          New_C:=((B - (7)+(C+D))) - (3 - A1); -- STUPID FORMULA
          WRITE (C, A1+New_C);
          -- WHAT ABOUT := B+D;
        END
        ''', upperReserved).should.be(
        'BeginSym ReadSym LParen Id Comma Id Comma Id Comma Id RParen '
        'SemiColon Id AssignOp Id PlusOp LParen Id MinusOp Id RParen MinusOp '
        'IntLiteral SemiColon Id AssignOp LParen LParen Id MinusOp LParen '
        'IntLiteral RParen PlusOp LParen Id PlusOp Id RParen RParen RParen '
        'MinusOp LParen IntLiteral MinusOp Id RParen SemiColon WriteSym '
        'LParen Id Comma Id PlusOp Id RParen SemiColon EndSym EofSym',
      );
    });
  });

  group('Given the HW#1 listing two', () {
    test('When scanned, then it yields the full original token stream', () {
      scanAllWith('''
        BEGIN
          READ(OPT, A, B);
          READ(OPT, C, D);
          Q_VAR_01 + 1 := (A+C)-(B-D);
          VAR_SPREAD:= 1234 + 3456 +
            --forgot to keep this on one line
            7894 -(A+B);
          WRITE(A, 75894589349);
        END --Phew, finally done.
        ''', upperReserved).should.be(
        'BeginSym ReadSym LParen Id Comma Id Comma Id RParen SemiColon '
        'ReadSym LParen Id Comma Id Comma Id RParen SemiColon Id PlusOp '
        'IntLiteral AssignOp LParen Id PlusOp Id RParen MinusOp LParen Id '
        'MinusOp Id RParen SemiColon Id AssignOp IntLiteral PlusOp IntLiteral '
        'PlusOp IntLiteral MinusOp LParen Id PlusOp Id RParen SemiColon '
        'WriteSym LParen Id Comma IntLiteral RParen SemiColon EndSym EofSym',
      );
    });
  });

  group('Given a source with an unbufferable character', () {
    test('When scanned, then it surfaces a lexical failure', () {
      // A lone backtick has no transition from the start state.
      final result = TableScanner().scan(r'`');
      result.isLeft().should.be(true);
      result.getLeft().toNullable()!.should.beOfType<LexicalFailure>();
    });
  });
}
