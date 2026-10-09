import 'package:fpdart/fpdart.dart';

import '../contracts/code_generator.dart';
import '../contracts/scanner.dart';
import '../domain/failures/compile_failure.dart';
import '../domain/grammar/grammar.dart';
import '../domain/grammar/production.dart';
import '../domain/semantic/records.dart';
import '../domain/semantic/semantic.dart';
import '../domain/tokens/token.dart';
import '../domain/tokens/token_type.dart';

/// Parse-stack entry kinds.
sealed class _Ps {}

/// A parseable symbol (terminal or nonterminal) occupying [slot] on the
/// semantic-stack attribute list.
final class _Sym implements _Ps {
  final String symbol;
  final int slot;
  _Sym(this.symbol, this.slot);
}

/// A region frame: the attribute-slot block for one production expansion.
final class _Frame {
  final int base;
  final int n;
  final int resultSlot;
  _Frame(this.base, this.n, this.resultSlot);
}

/// End-of-production marker; reduces the region when reached.
final class _End implements _Ps {
  final _Frame frame;
  _End(this.frame);
}

/// A semantic `#Action` symbol, executed (rather than just popped) here.
final class _Act implements _Ps {
  final String raw;
  _Act(this.raw);
}

/// The concrete three-address code generator ([CodeGenerator] adapter).
///
/// Drives the same LL(1) parse table as [PredictiveLlParser] but **executes**
/// each `#Action` as it is reached: it maintains a semantic-stack of attribute
/// slots (one per parseable right-hand symbol plus `$$`), reduces each region
/// when its end-of-production marker is hit, and calls the [Semantic]
/// routines to emit `Declare` / `ADD` / `SUB` / `Store` / `Read` / `Write` /
/// `Halt`. This is the part the original 2016 driver left unwired.
final class SemanticCodeGenerator implements CodeGenerator {
  final Scanner _scanner;
  final Grammar _grammar;
  final Semantic _semantic;

  /// Injects the [Scanner] and [Grammar] the generator compiles against.
  SemanticCodeGenerator(this._scanner, this._grammar) : _semantic = Semantic();

  @override
  Either<CompileFailure, List<String>> generate(String source) {
    final scan = _scanner.scan(source);
    if (scan.isLeft()) {
      return Left<CompileFailure, List<String>>(scan.getLeft().toNullable()!);
    }
    return _run(scan.getRight().toNullable()!);
  }

  Either<CompileFailure, List<String>> _run(List<Token> tokens) {
    final attrs = <SemanticRecord?>[];
    final frames = <_Frame>[];
    final pstack = <_Ps>[];
    var index = 0;
    var cur = const Token(TokenType.id, '');
    var nxt = const Token(TokenType.id, '');

    Token fetch() => index < tokens.length
        ? tokens[index++]
        : const Token(TokenType.eof, 'EofSym');
    void step() {
      cur = nxt;
      nxt = fetch();
    }

    step();
    step();

    pstack.insert(0, _Sym(defaultStartSymbol, -1));

    while (pstack.isNotEmpty) {
      final entry = pstack.removeAt(0);
      if (entry is _End) {
        final f = entry.frame;
        final result = attrs[f.base + f.n];
        if (f.resultSlot >= 0 && result != null) {
          attrs[f.resultSlot] = result;
        }
        frames.removeLast();
      } else if (entry is _Act) {
        _execute(entry.raw, frames, attrs);
      } else if (entry is _Sym) {
        final sym = entry.symbol;
        if (_grammar.nonTerminals.contains(sym)) {
          final predicted = _grammar.t(sym, cur.type.name);
          if (predicted == null) {
            return Left(
              SyntaxFailure(
                '[Parser] No production for $sym on token ${cur.type.name}.',
              ),
            );
          }
          _expand(_production(predicted), entry, frames, attrs, pstack);
        } else if (_grammar.terminals.contains(sym)) {
          if (sym == cur.type.name) {
            attrs[entry.slot] = _terminalAttr(cur);
            step();
          } else {
            return Left(
              SyntaxFailure(
                '[Parser] Expected terminal $sym but saw ${cur.type.name}.',
              ),
            );
          }
        } else {
          return Left(
            SyntaxFailure('[Parser] Unexpected stack symbol "$sym".'),
          );
        }
      }
    }
    return Right(List.unmodifiable(_semantic.codeLines));
  }

  /// Expands a nonterminal into its production's symbols and actions.
  void _expand(
    Production prod,
    _Sym entry,
    List<_Frame> frames,
    List<SemanticRecord?> attrs,
    List<_Ps> pstack,
  ) {
    // An epsilon production (`-> λ`) pushes no parseable symbols.
    final isEpsilon = prod.rhsActions.contains(lambdaMarker);
    final n = isEpsilon
        ? 0
        : prod.rhsActions.where((s) => !s.startsWith('#')).length;
    final base = attrs.length;
    attrs.addAll(List.generate(n + 1, (_) => null));
    final frame = _Frame(base, n, entry.slot);
    frames.add(frame);

    final entries = <_Ps>[];
    if (!isEpsilon) {
      var slot = 0;
      for (final s in prod.rhsActions) {
        if (s.startsWith('#')) {
          entries.add(_Act(s));
        } else {
          entries.add(_Sym(s, base + slot++));
        }
      }
    }
    entries.add(_End(frame));
    pstack.insertAll(0, entries);
  }

  Production _production(int number) =>
      _grammar.productions.firstWhere((p) => p.number == number);

  SemanticRecord? _terminalAttr(Token t) => switch (t.type) {
    TokenType.id => SemanticRecord.expression(ExpressionRecord.id(t.lexeme)),
    TokenType.intLiteral => SemanticRecord.expression(
      ExpressionRecord.literal(int.parse(t.lexeme)),
    ),
    TokenType.plusOp => SemanticRecord.operator(
      OperatorRecord(OperatorKind.plus),
    ),
    TokenType.minusOp => SemanticRecord.operator(
      OperatorRecord(OperatorKind.minus),
    ),
    _ => null,
  };

  /// Runs a semantic action against the innermost region.
  void _execute(String raw, List<_Frame> frames, List<SemanticRecord?> attrs) {
    final f = frames.last;
    final base = f.base;
    final n = f.n;

    SemanticRecord slot(int k) => attrs[base + k - 1]!;
    void setResult(SemanticRecord v) => attrs[base + n] = v;

    final name = raw.startsWith('#') ? raw.substring(1) : raw;
    final nameEnd = name.indexOf('(');
    final op = nameEnd >= 0 ? name.substring(0, nameEnd) : name;
    final args = _argsOf(raw);

    switch (op) {
      case 'Start':
        break;
      case 'ProcessId':
        final id = (slot(1).expression)!;
        setResult(SemanticRecord.expression(_semantic.processId(id.name)));
      case 'ProcessLiteral':
        final lit = (slot(1).expression)!;
        setResult(
          SemanticRecord.expression(_semantic.processLiteral(lit.value!)),
        );
      case 'ProcessOp':
        setResult(slot(1));
      case 'Copy':
        if (args.length >= 2) {
          final from = _argSlot(args[0], base, n);
          final to = _argSlot(args[1], base, n);
          attrs[to] = attrs[from];
        }
      case 'GenInfix':
        if (frames.length >= 2) {
          final opRec = (slot(1).operator)!;
          final operand = (slot(2).expression)!;
          // The accumulated left operand lives in the enclosing <expression>
          // region's second slot (seeded by its #Copy($1,$2)).
          final parent = frames[frames.length - 2];
          final acc = (attrs[parent.base + 1] as SemanticRecord).expression!;
          final temp = _semantic.genInfix(acc, opRec, operand);
          attrs[parent.base + 1] = SemanticRecord.expression(temp);
          setResult(SemanticRecord.expression(temp));
        }
      case 'Assign':
        if (args.isNotEmpty) {
          final target = (slot(1).expression)!;
          final source = slot(3);
          _semantic.assign(target, source);
        }
      case 'ReadId':
        final id = (slot(1).expression)!;
        _semantic.readId(ExpressionRecord.id(id.name));
      case 'WriteExpr':
        final source = slot(1);
        _semantic.writeExpr(source);
      case 'Finish':
        _semantic.finish();
      default:
        break;
    }
  }

  /// Maps a `$k` / `$$` argument to its semantic-stack slot index.
  int _argSlot(String arg, int base, int n) =>
      arg == r'$$' ? base + n : base + int.parse(arg.substring(1)) - 1;

  List<String> _argsOf(String raw) {
    final open = raw.indexOf('(');
    if (open < 0) return const [];
    final close = raw.lastIndexOf(')');
    if (close <= open) return const [];
    return raw
        .substring(open + 1, close)
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
