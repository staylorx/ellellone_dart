import '../domain/tokens/token_type.dart';

/// Parses a reserved-token dictionary into a [Map] of [TokenType] to lexeme.
///
/// The format is one `kindName = lexeme` pair per line; blank lines and lines
/// starting with `#` are ignored, and each kind name is a [TokenType] enum
/// name (e.g. `begin`, `end`, `read`, `write`, `eofScan`). The `$` end marker
/// is written as `eofScan = $`. A malformed or unknown line raises a
/// [FormatException] — a configuration error surfaced at the boundary.
///
/// A program keyword set is created and given to a [TableScanner] when you
/// want a language whose reserved words differ from the built-in defaults
/// (`begin`/`end`/`read`/`write`/`$`).
Map<TokenType, String> parseReservedTokens(String source) {
  final dict = <TokenType, String>{};
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq < 0) {
      throw FormatException('Expected "kindName = lexeme", found "$line".');
    }
    final name = line.substring(0, eq).trim();
    final lexeme = line.substring(eq + 1).trim();
    final kind = _kindByName(name);
    if (kind == null) {
      throw FormatException('Unknown token kind "$name".');
    }
    dict[kind] = lexeme;
  }
  return dict;
}

/// Resolves a [TokenType] by its enum identifier, or `null` when unknown.
///
/// The enum's `name` getter is overridden with the symbolic token name
/// (`BeginSym`), so the enum *identifier* (`begin`) is matched here.
TokenType? _kindByName(String name) {
  for (final type in TokenType.values) {
    if (type.toString() == 'TokenType.$name') return type;
  }
  return null;
}
