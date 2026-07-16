import 'package:supabase_flutter/supabase_flutter.dart';

import 'premium_wallet.dart';

abstract interface class EconomyRepository {
  Future<PremiumWallet> fetchWallet();

  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  });
}

class PurchaseRejectedException implements Exception {
  const PurchaseRejectedException(this.message);
  final String message;

  @override
  String toString() => 'PurchaseRejectedException: $message';
}

class SupabaseEconomyRepository implements EconomyRepository {
  SupabaseEconomyRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PremiumWallet> fetchWallet() async {
    final row = await _client
        .from('wallets')
        .select('royal_jade, royal_jade_debt, version')
        .single();
    return PremiumWallet(
      balance: _integer(row['royal_jade']),
      debt: _integer(row['royal_jade_debt']),
      version: _integer(row['version']),
    );
  }

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'verify-google-play-purchase',
        body: {
          'productId': productId,
          'purchaseToken': purchaseToken,
          'packageName': packageName,
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw PurchaseRejectedException(
          'verification returned ${response.status}',
        );
      }
    } on FunctionException catch (error) {
      throw PurchaseRejectedException(error.toString());
    }
  }

  static int _integer(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('wallet field is not an integer');
  }
}
