/// Exact portable recurrence, with an explicit legacy browser reconstruction.
final class SeededSequence {
  SeededSequence(int seed, int index, {bool legacyBrowser = false})
    : _legacyBrowser = legacyBrowser,
      _state =
          (BigInt.from(seed) & _mask) ^
          ((legacyBrowser
                  ? BigInt.from((index.toDouble() + 1) * 0x45d9f3b)
                  : (BigInt.from(index) + BigInt.one) *
                        BigInt.from(0x45d9f3b)) &
              _mask);
  static final _mask = BigInt.from(0x7fffffff);
  final bool _legacyBrowser;
  BigInt _state;
  int pick(int bound) {
    if (_legacyBrowser) {
      final product = _state.toDouble() * 1103515245.0;
      _state = BigInt.from(product + 12345.0) & _mask;
    } else {
      _state = (_state * BigInt.from(1103515245) + BigInt.from(12345)) & _mask;
    }
    return 1 + (_state % BigInt.from(bound)).toInt();
  }
}
