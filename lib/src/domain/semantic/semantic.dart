import 'records.dart';
import 'symbol_table.dart';

/// The semantic-action library: builds three-address code instructions from
/// the attributes the parser would push onto its [SemanticStack].
///
/// These routines mirror the original `semantic.js`: they are the seam that
/// the grammar's `#Action` symbols would fire, and are kept coherent and
/// tested even though the LL(1) driver itself pops action symbols without
/// calling them (faithful to the original; wiring them is a BACKLOG item).
final class Semantic {
  final SymbolTable _symbolTable;

  /// The three-address code lines generated so far, in order.
  final List<String> codeLines;
  int _maxTemp;

  /// Creates a semantic builder over [symbolTable], with temporaries numbered
  /// from [startTemp].
  Semantic({SymbolTable? symbolTable, int startTemp = 0})
    : _symbolTable = symbolTable ?? SymbolTable(),
      codeLines = <String>[],
      _maxTemp = startTemp;

  /// Builds an instruction from [op] and its comma-joined [args], and records
  /// it in [codeLines].
  String generate(String op, [List<String> args = const []]) {
    final instruction = args.isEmpty ? op : '$op ${args.join(',')}';
    codeLines.add(instruction);
    return instruction;
  }

  /// Declares [symbol] on first encounter and emits a `Declare` line.
  String checkId(String symbol) {
    if (!_symbolTable.lookup(symbol)) {
      _symbolTable.enter(symbol);
      return generate('Declare', [symbol, 'Integer']);
    }
    return '';
  }

  /// Allocates the next temporary, declaring it, and returns its name.
  String getTemp() {
    _maxTemp++;
    final name = 'Temp&$_maxTemp';
    checkId(name);
    return name;
  }

  /// The code operand for an expression: its name or literal value.
  String extractExpr(ExpressionRecord e) => switch (e.kind) {
    ExpressionKind.literal => e.value!.toString(),
    _ => e.name,
  };

  /// The arithmetic mnemonic for an operator.
  String extractOp(OperatorRecord o) =>
      o.kind == OperatorKind.plus ? 'ADD ' : 'SUB ';

  /// The code operand for a semantic stack attribute.
  String extractSemantic(SemanticRecord r) => switch (r.kind) {
    SemanticRecordKind.operator => extractOp(r.operator!),
    SemanticRecordKind.expression => extractExpr(r.expression!),
    SemanticRecordKind.error => '',
  };

  /// Emits `Store source,target`.
  String assign(ExpressionRecord target, SemanticRecord source) =>
      generate('Store', [extractSemantic(source), target.name]);

  /// Emits `Read variable,Integer`.
  String readId(ExpressionRecord variable) =>
      generate('Read', [variable.name, 'Integer']);

  /// Emits `Write expression,Integer`.
  String writeExpr(SemanticRecord expression) =>
      generate('Write', [extractSemantic(expression), 'Integer']);

  /// Emits `ADD|SUB left,right,temp` and returns the new temporary record.
  ExpressionRecord genInfix(
    ExpressionRecord left,
    OperatorRecord op,
    ExpressionRecord right,
  ) {
    final temp = ExpressionRecord.temp(getTemp());
    generate(extractOp(op), [extractExpr(left), extractExpr(right), temp.name]);
    return temp;
  }

  /// Turns an identifier attribute into an id expression record, declaring it.
  ExpressionRecord processId(String name) {
    checkId(name);
    return ExpressionRecord.id(name);
  }

  /// Turns a literal attribute into a literal expression record.
  ExpressionRecord processLiteral(int value) => ExpressionRecord.literal(value);

  /// Turns a `PlusOp`/`MinusOp` token name into an operator record.
  OperatorRecord processOp(String tokenName) => OperatorRecord(
    tokenName == 'PlusOp' ? OperatorKind.plus : OperatorKind.minus,
  );

  /// The final instruction of a generated program.
  String finish() => generate('Halt');
}
