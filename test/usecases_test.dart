import 'package:ellellone/ellellone.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// A hand-rolled fake used to prove a usecase depends only on the [Scanner]
/// contract (dependency inversion: inject the seam, don't construct the
/// concrete lexer).
final class _FakeScanner implements Scanner {
  @override
  Either<LexicalFailure, List<Token>> scan(String source) => Right(const [
    Token(TokenType.begin, 'begin'),
    Token(TokenType.eofScan, '\$'),
  ]);
}

void main() {
  group('Given a ScanUsecase wired to a fake scanner', () {
    test('Then call returns the injected seam untouched', () {
      final scan = ScanUsecase(_FakeScanner());
      final result = scan.call('anything');
      result.isRight().should.be(true);
      final tokens = result.getRight().toNullable()!;
      tokens.length.should.be(2);
      tokens.first.type.should.be(TokenType.begin);
      tokens.last.type.should.be(TokenType.eofScan);
    });
  });

  group('Given a ScanUsecase wired to the real TableScanner', () {
    test('Then call tokenizes a real program end to end', () {
      final scan = ScanUsecase(TableScanner());
      final result = scan.call('begin A; end \$');
      result.isRight().should.be(true);
      result.getRight().toNullable()!.first.type.should.be(TokenType.begin);
    });
  });
}
