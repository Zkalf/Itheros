/// Seeded xorshift32 generator whose whole state is one integer, so it can be
/// saved with the game. `dart:math` Random cannot be serialised.
class Rng {
  Rng.fromState(int state)
    : state = (state & _mask) == 0 ? _fallback : state & _mask;

  /// Mixes [seed] so that nearby seeds start far apart.
  factory Rng.seeded(int seed) => Rng.fromState((seed * 0x9E3779B1) & _mask);

  static const _mask = 0xFFFFFFFF;
  static const _fallback = 0x2545F491;

  int state;

  int nextUint32() {
    var x = state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    return state = x & _mask;
  }

  /// Uniform in [0, 1).
  double nextDouble() => nextUint32() / 4294967296.0;
}
