class PremiumWallet {
  PremiumWallet({required int balance, required int debt, required int version})
    : balance = _requireNonNegative('balance', balance),
      debt = _requireNonNegative('debt', debt),
      version = _requireNonNegative('version', version);

  final int balance;
  final int debt;
  final int version;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumWallet &&
          balance == other.balance &&
          debt == other.debt &&
          version == other.version;

  @override
  int get hashCode => Object.hash(balance, debt, version);

  static int _requireNonNegative(String name, int value) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'must not be negative');
    }
    return value;
  }
}
