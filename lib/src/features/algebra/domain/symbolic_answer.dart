import '../../learning/domain/numeric_answer_contract.dart';

enum SymbolicForm { equivalent, collected }

/// Version-one exact polynomials over real x; variable divisors are unsupported.
final class SymbolicAnswer {
  SymbolicAnswer(String expected, {this.form = SymbolicForm.equivalent})
    : _expected = _Parser(expected).parse();
  final SymbolicForm form;
  final _Value _expected;

  AnswerMark mark(String input) {
    try {
      final value = _Parser(input).parse();
      final equivalent = value.key == _expected.key;
      final collected =
          value.expanded && value.terms.toSet().length == value.terms.length;
      return AnswerMark(
        normalizedInput: input.trim(),
        verdict: equivalent && (form == SymbolicForm.equivalent || collected)
            ? AnswerVerdict.correct
            : AnswerVerdict.incorrect,
      );
    } on FormatException {
      return const AnswerMark(
        normalizedInput: '',
        verdict: AnswerVerdict.invalid,
      );
    }
  }
}

Never _invalid() => throw const FormatException('Unsupported polynomial input');

final class _Rational {
  _Rational(BigInt n, BigInt d) {
    if (d == BigInt.zero) _invalid();
    final gcd = n.gcd(d);
    numerator = n ~/ gcd * (d.isNegative ? -BigInt.one : BigInt.one);
    denominator = d.abs() ~/ gcd;
    if (numerator.bitLength > 256 || denominator.bitLength > 256) _invalid();
  }
  factory _Rational.integer(int n) => _Rational(BigInt.from(n), BigInt.one);
  late final BigInt numerator;
  late final BigInt denominator;
  bool get zero => numerator == BigInt.zero;
  _Rational operator +(_Rational other) => _Rational(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );
  _Rational operator -() => _Rational(-numerator, denominator);
  _Rational operator *(_Rational other) =>
      _Rational(numerator * other.numerator, denominator * other.denominator);
  _Rational inverse() => _Rational(denominator, numerator);
  String get key => '$numerator/$denominator';
}

final class _Value {
  _Value(
    Map<int, _Rational> coefficients,
    this.terms, {
    this.expanded = true,
    this.hasVariable = false,
  }) : coefficients = Map.of(coefficients)..removeWhere((_, c) => c.zero) {
    if (this.coefficients.keys.any((degree) => degree > 8)) _invalid();
  }
  factory _Value.constant(_Rational c) => _Value({0: c}, c.zero ? [] : [0]);
  final Map<int, _Rational> coefficients;
  final List<int> terms;
  final bool expanded;
  final bool hasVariable;
  bool get variable => coefficients.keys.any((degree) => degree > 0);
  String get key {
    final degrees = coefficients.keys.toList()..sort();
    return degrees.map((d) => '$d:${coefficients[d]!.key}').join(',');
  }

  _Value negate() => _Value(
    coefficients.map((d, c) => MapEntry(d, -c)),
    terms,
    expanded: expanded,
    hasVariable: hasVariable,
  );
  _Value add(_Value other) {
    final result = Map<int, _Rational>.of(coefficients);
    for (final entry in other.coefficients.entries) {
      result[entry.key] =
          (result[entry.key] ?? _Rational.integer(0)) + entry.value;
    }
    return _Value(
      result,
      [...terms, ...other.terms],
      expanded: expanded && other.expanded,
      hasVariable: hasVariable || other.hasVariable,
    );
  }

  _Value multiply(_Value other) {
    final result = <int, _Rational>{};
    for (final a in coefficients.entries) {
      for (final b in other.coefficients.entries) {
        final degree = a.key + b.key;
        result[degree] =
            (result[degree] ?? _Rational.integer(0)) + a.value * b.value;
      }
    }
    return _Value(
      result,
      result.entries.where((e) => !e.value.zero).map((e) => e.key).toList(),
      expanded:
          expanded &&
          other.expanded &&
          !(variable && terms.length > 1) &&
          !(other.variable && other.terms.length > 1),
      hasVariable: hasVariable || other.hasVariable,
    );
  }

  _Value divide(_Value other) {
    if (other.hasVariable || other.coefficients.isEmpty) _invalid();
    return multiply(_Value.constant(other.coefficients[0]!.inverse()));
  }
}

final class _Parser {
  _Parser(String source) : source = source.trim() {
    if (source.length > 256) _invalid();
  }
  final String source;
  int position = 0;
  int depth = 0;
  String get next {
    while (position < source.length &&
        RegExp(r'\s').hasMatch(source[position])) {
      position++;
    }
    return position == source.length ? '' : source[position];
  }

  bool take(String token) {
    if (next != token) return false;
    position++;
    return true;
  }

  _Value parse() {
    final result = sum();
    if (next.isNotEmpty) _invalid();
    return result;
  }

  _Value sum() {
    var result = product();
    while (true) {
      if (take('+')) {
        result = result.add(product());
      } else if (take('-')) {
        result = result.add(product().negate());
      } else {
        return result;
      }
    }
  }

  _Value product() {
    var result = unary();
    while (true) {
      if (take('*')) {
        result = result.multiply(unary());
      } else if (take('/')) {
        result = result.divide(unary());
      } else if (next == 'x' || next == '(') {
        result = result.multiply(unary());
      } else {
        return result;
      }
    }
  }

  _Value unary() {
    if (++depth > 32) _invalid();
    final _Value result;
    if (take('+')) {
      result = unary();
    } else if (take('-')) {
      result = unary().negate();
    } else {
      result = power();
    }
    depth--;
    return result;
  }

  _Value power() {
    final base = atom();
    if (!take('^')) return base;
    final start = position;
    while (next.isNotEmpty && RegExp(r'[0-9]').hasMatch(next)) {
      position++;
    }
    final exponent = int.tryParse(source.substring(start, position).trim());
    if (exponent == null || exponent > 8) _invalid();
    var result = _Value.constant(_Rational.integer(1));
    for (var i = 0; i < exponent; i++) {
      result = result.multiply(base);
    }
    // Even x^0 remains syntactically variable for the divisor restriction.
    return _Value(
      result.coefficients,
      result.terms,
      expanded: result.expanded,
      hasVariable: base.hasVariable,
    );
  }

  _Value atom() {
    if (take('(')) {
      final result = sum();
      if (!take(')')) _invalid();
      return result;
    }
    if (take('x')) {
      return _Value({1: _Rational.integer(1)}, [1], hasVariable: true);
    }
    final start = position;
    // Force whitespace normalization before remembering the literal start.
    final first = next;
    if (first.isEmpty || !RegExp(r'[0-9.]').hasMatch(first)) _invalid();
    final match = RegExp(
      r'(?:\d+(?:\.\d*)?|\.\d+)',
    ).matchAsPrefix(source, position);
    if (match == null) _invalid();
    position = match.end;
    final literal = source.substring(start, position).trim();
    final parts = literal.split('.');
    final decimals = parts.length == 1 ? 0 : parts[1].length;
    if (decimals > 6) _invalid();
    return _Value.constant(
      _Rational(
        BigInt.parse(literal.replaceAll('.', '')),
        BigInt.from(10).pow(decimals),
      ),
    );
  }
}
