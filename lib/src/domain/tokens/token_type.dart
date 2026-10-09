/// The kinds of [Token] a [Scanner] can produce.
///
/// These mirror the symbolic names the original Node scanner emitted. The
/// first block are the fixed token classes; the second block are the reserved
/// keywords the scanner recognizes when their lexeme appears in the reserved
/// dictionary.
enum TokenType {
  // Fixed scanner token classes.

  /// An identifier lexeme.
  id('Id'),

  /// An integer literal lexeme.
  intLiteral('IntLiteral'),

  /// The `+` operator.
  plusOp('PlusOp'),

  /// The `-` operator.
  minusOp('MinusOp'),

  /// The `=` assignment operator.
  assignOp('AssignOp'),

  /// A comma separator.
  comma('Comma'),

  /// A semicolon terminator.
  semiColon('SemiColon'),

  /// An opening parenthesis.
  lParen('LParen'),

  /// A closing parenthesis.
  rParen('RParen'),

  /// The `->` production marker.
  produces('Produces'),

  /// An angle-bracket nonterminal symbol.
  nonTerminal('NonTerminal'),

  /// The empty-production marker.
  lambda('Lambda'),

  /// A semantic `#Action` symbol.
  action('Action'),

  /// The end-of-input token.
  eof('EofSym'),

  /// A skipped whitespace lexeme.
  emptySpace('EmptySpace'),

  /// A skipped `--` comment lexeme.
  comment('Comment'),

  // Reserved keywords.

  /// The reserved `begin` keyword.
  begin('BeginSym'),

  /// The reserved `end` keyword.
  end('EndSym'),

  /// The reserved `read` keyword.
  read('ReadSym'),

  /// The reserved `write` keyword.
  write('WriteSym'),

  /// The end-of-input sentinel keyword.
  eofScan('EOfScan');

  /// The symbolic name used in scanner output, the grammar's terminal
  /// vocabulary, and the LL(1) parse table.
  final String name;

  const TokenType(this.name);

  /// The reserved-keyword and skipped lexemes are recognized by the scanner
  /// but never surface as parseable terminals; [isTerminal] tells the grammar
  /// whether a kind is a real symbol it should track.
  bool get isTerminal => switch (this) {
    emptySpace || comment => false,
    _ => true,
  };
}
