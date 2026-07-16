import 'account_session.dart';

abstract interface class AccountService {
  Stream<AccountSession> get changes;
  AccountSession get current;
  Future<AccountSession> ensureGuest();
  Future<AccountSession> connectGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}
