import 'dart:math';

/// Exception khusus untuk error kalkulasi, pesannya ramah ditampilkan ke user.
class CalcError implements Exception {
  final String message;
  CalcError(this.message);
  @override
  String toString() => message;
}

class _Token {
  final String type; // num, op, ident, lparen, rparen, end
  final String text;
  final double? value;
  _Token(this.type, this.text, [this.value]);
}

class _Lexer {
  final String src;
  int pos = 0;
  _Lexer(this.src);

  List<_Token> tokenize() {
    final tokens = <_Token>[];
    while (pos < src.length) {
      final c = src[pos];
      if (c == ' ') {
        pos++;
        continue;
      }
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        final start = pos;
        while (pos < src.length && RegExp(r'[0-9.]').hasMatch(src[pos])) {
          pos++;
        }
        final text = src.substring(start, pos);
        final val = double.tryParse(text);
        if (val == null) throw CalcError('Angka tidak valid: $text');
        tokens.add(_Token('num', text, val));
        continue;
      }
      if (RegExp(r'[a-zA-Z]').hasMatch(c)) {
        final start = pos;
        while (pos < src.length && RegExp(r'[a-zA-Z]').hasMatch(src[pos])) {
          pos++;
        }
        tokens.add(_Token('ident', src.substring(start, pos)));
        continue;
      }
      if ('+-*/^!%()'.contains(c)) {
        tokens.add(
          _Token(c == '(' ? 'lparen' : (c == ')' ? 'rparen' : 'op'), c),
        );
        pos++;
        continue;
      }
      // Simbol × dan ÷ dari tombol UI diterjemahkan sebelum sampai di sini,
      // tapi jaga-jaga bila lolos:
      if (c == '×') {
        tokens.add(_Token('op', '*'));
        pos++;
        continue;
      }
      if (c == '÷') {
        tokens.add(_Token('op', '/'));
        pos++;
        continue;
      }
      throw CalcError('Karakter tidak dikenal: "$c"');
    }
    tokens.add(_Token('end', ''));
    return tokens;
  }
}

class _Parser {
  final List<_Token> tokens;
  int pos = 0;
  _Parser(this.tokens);

  _Token get cur => tokens[pos];

  double parse() {
    if (cur.type == 'end') throw CalcError('Ekspresi kosong');
    final v = _expression();
    if (cur.type != 'end') {
      throw CalcError('Ekspresi tidak valid dekat "${cur.text}"');
    }
    if (v.isNaN || v.isInfinite) throw CalcError('Hasil tidak valid');
    return v;
  }

  double _expression() {
    var v = _term();
    while (cur.type == 'op' && (cur.text == '+' || cur.text == '-')) {
      final op = cur.text;
      pos++;
      final r = _term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double _term() {
    var v = _power();
    while (cur.type == 'op' && (cur.text == '*' || cur.text == '/')) {
      final op = cur.text;
      pos++;
      final r = _power();
      if (op == '/') {
        if (r == 0) throw CalcError('Tidak bisa dibagi dengan 0');
        v = v / r;
      } else {
        v = v * r;
      }
    }
    return v;
  }

  double _power() {
    final v = _unary();
    if (cur.type == 'op' && cur.text == '^') {
      pos++;
      final r = _power(); // right-associative
      return pow(v, r).toDouble();
    }
    return v;
  }

  double _unary() {
    if (cur.type == 'op' && cur.text == '-') {
      pos++;
      return -_unary();
    }
    if (cur.type == 'op' && cur.text == '+') {
      pos++;
      return _unary();
    }
    return _postfix();
  }

  double _postfix() {
    var v = _primary();
    while (cur.type == 'op' && (cur.text == '!' || cur.text == '%')) {
      if (cur.text == '!') {
        v = _factorial(v);
      } else {
        v = v / 100;
      }
      pos++;
    }
    return v;
  }

  double _primary() {
    if (cur.type == 'num') {
      final v = cur.value!;
      pos++;
      return v;
    }
    if (cur.type == 'lparen') {
      pos++;
      final v = _expression();
      _expect('rparen', ')');
      return v;
    }
    if (cur.type == 'ident') {
      final name = cur.text.toLowerCase();
      pos++;
      if (name == 'pi') return pi;
      if (name == 'e') return e;
      if (name == 'ans') return 0; // ditangani di layer UI, fallback 0
      _expect('lparen', '(');
      final arg = _expression();
      _expect('rparen', ')');
      switch (name) {
        case 'sqrt':
          if (arg < 0) throw CalcError('Akar dari bilangan negatif');
          return sqrt(arg);
        case 'abs':
          return arg.abs();
        case 'sin':
          return sin(arg * pi / 180);
        case 'cos':
          return cos(arg * pi / 180);
        case 'tan':
          return tan(arg * pi / 180);
        case 'log':
          return log(arg) / ln10;
        case 'ln':
          return log(arg);
        default:
          throw CalcError('Fungsi tidak dikenal: $name');
      }
    }
    throw CalcError('Ekspresi tidak valid dekat "${cur.text}"');
  }

  void _expect(String type, String symbol) {
    if (cur.type != type) {
      throw CalcError('Diharapkan "$symbol", ditemukan "${cur.text}"');
    }
    pos++;
  }

  double _factorial(double v) {
    if (v < 0 || v != v.roundToDouble()) {
      throw CalcError('Faktorial hanya untuk bilangan bulat positif');
    }
    if (v > 170) throw CalcError('Angka terlalu besar untuk faktorial');
    double r = 1;
    for (int i = 2; i <= v.round(); i++) {
      r *= i;
    }
    return r;
  }
}

/// Menghitung nilai dari string ekspresi matematika.
/// Mendukung: + - * / ^ (pangkat) ! (faktorial) % (persen)
/// sqrt(), abs(), sin(), cos(), tan(), log(), ln(), pi, e, tanda kurung.
double evaluateExpression(String expr) {
  final normalized = expr.replaceAll('×', '*').replaceAll('÷', '/');
  final tokens = _Lexer(normalized).tokenize();
  return _Parser(tokens).parse();
}

/// Faktorisasi prima sederhana, dipakai untuk fitur tambahan (opsional),
/// meniru gaya tampilan pada contoh gambar (2052 = 2^2 x 3^3 x 19).
String primeFactorizationSteps(int n) {
  if (n < 2) return '$n tidak memiliki faktorisasi prima';
  final factors = <int, int>{};
  int remaining = n;
  int divisor = 2;
  while (divisor * divisor <= remaining) {
    while (remaining % divisor == 0) {
      factors[divisor] = (factors[divisor] ?? 0) + 1;
      remaining ~/= divisor;
    }
    divisor++;
  }
  if (remaining > 1) {
    factors[remaining] = (factors[remaining] ?? 0) + 1;
  }
  final parts = factors.entries
      .map((e) => e.value > 1 ? '${e.key}^${e.value}' : '${e.key}')
      .join(' x ');
  return '$n = $parts';
}
