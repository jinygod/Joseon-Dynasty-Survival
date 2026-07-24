enum ExperienceOwner { dropped, mounted, compressed, magnetized, granted }

class ExperienceLedger {
  final Map<ExperienceOwner, int> _values = {
    for (final owner in ExperienceOwner.values) owner: 0,
  };

  int get totalOwnedExperience =>
      _values.values.fold(0, (total, value) => total + value);

  int valueOf(ExperienceOwner owner) => _values[owner]!;

  void add(ExperienceOwner owner, int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    _values[owner] = _values[owner]! + amount;
  }

  void transfer({
    required ExperienceOwner from,
    required ExperienceOwner to,
    required int amount,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    if (_values[from]! < amount) {
      throw StateError('Experience owner $from contains less than $amount');
    }
    _values[from] = _values[from]! - amount;
    _values[to] = _values[to]! + amount;
  }
}
