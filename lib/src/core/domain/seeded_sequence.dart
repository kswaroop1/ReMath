/// Exact version-one recurrence shared by VM and JavaScript runtimes.
final class SeededSequence {
  SeededSequence(int seed, int index)
    : _state =
          (BigInt.from(seed) & _mask) ^
          ((BigInt.from(index) + BigInt.one) * BigInt.from(0x45d9f3b) & _mask);
  static final _mask = BigInt.from(0x7fffffff);
  BigInt _state;
  int pick(int bound) {
    _state = (_state * BigInt.from(1103515245) + BigInt.from(12345)) & _mask;
    return 1 + (_state % BigInt.from(bound)).toInt();
  }
}
