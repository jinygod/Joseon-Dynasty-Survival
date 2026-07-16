class AccountSession {
  const AccountSession._({
    required this.userId,
    required this.kind,
    this.email,
  });

  const AccountSession.signedOut()
    : userId = null,
      kind = AccountSessionKind.signedOut,
      email = null;

  factory AccountSession.anonymous({required String userId}) =>
      AccountSession._(
        userId: _requireNonEmpty('userId', userId),
        kind: AccountSessionKind.anonymous,
      );

  factory AccountSession.google({
    required String userId,
    required String email,
  }) => AccountSession._(
    userId: _requireNonEmpty('userId', userId),
    kind: AccountSessionKind.google,
    email: _requireNonEmpty('email', email),
  );

  final String? userId;
  final AccountSessionKind kind;
  final String? email;

  bool get isAuthenticated => kind != AccountSessionKind.signedOut;
  bool get isAnonymous => kind == AccountSessionKind.anonymous;
  bool get isPermanent => kind == AccountSessionKind.google;

  static String _requireNonEmpty(String name, String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountSession &&
          userId == other.userId &&
          kind == other.kind &&
          email == other.email;

  @override
  int get hashCode => Object.hash(userId, kind, email);
}

enum AccountSessionKind { signedOut, anonymous, google }
