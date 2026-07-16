class AccountSession {
  const AccountSession({
    required this.userId,
    required this.isAnonymous,
    this.email,
  });

  const AccountSession.signedOut()
    : userId = null,
      isAnonymous = false,
      email = null;

  final String? userId;
  final bool isAnonymous;
  final String? email;

  bool get isAuthenticated => userId != null;
  bool get isPermanent => isAuthenticated && !isAnonymous;
}
