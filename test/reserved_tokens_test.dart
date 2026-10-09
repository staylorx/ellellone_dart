import 'package:ellellone/ellellone.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  group('Given a reserved-token dictionary file', () {
    test('Then it parses kind = lexeme pairs and skips comments', () {
      final dict = parseReservedTokens(
        '# a demo language\n'
        'begin = START\n'
        'end = STOP\n'
        'eofScan = \$',
      );
      dict.length.should.be(3);
      dict[TokenType.begin].should.be('START');
      dict[TokenType.end].should.be('STOP');
      dict[TokenType.eofScan].should.be('\$');
    });

    test('Then a TableScanner recognizes the custom keywords', () {
      final scan = TableScanner(
        reserved: parseReservedTokens(
          'begin = START\nend = STOP\nread = GET\nwrite = PUT\neofScan = \$',
        ),
      );
      final result = scan.scan('START A := 1 + A; STOP \$');
      result.isRight().should.be(true);
      final tokens = result.getRight().toNullable()!;
      tokens.first.type.should.be(TokenType.begin);
      tokens.last.type.should.be(TokenType.eofScan);
    });
  });

  group('Given a malformed dictionary', () {
    test('Then an unknown kind raises FormatException', () {
      Object? caught;
      try {
        parseReservedTokens('begin = START\nbogusKind = x');
      } catch (e) {
        caught = e;
      }
      caught.should.beOfType<FormatException>();
    });

    test('Then a line without "=" raises FormatException', () {
      Object? caught;
      try {
        parseReservedTokens('begin');
      } catch (e) {
        caught = e;
      }
      caught.should.beOfType<FormatException>();
    });
  });
}
