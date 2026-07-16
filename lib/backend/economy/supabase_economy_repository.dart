import 'package:supabase_flutter/supabase_flutter.dart';

import 'premium_wallet.dart';

abstract interface class EconomyRepository {
  Future<PremiumWallet> fetchWallet();

  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  });
}

class PurchaseVerificationResult {
  const PurchaseVerificationResult({
    required this.accepted,
    required this.duplicate,
  });

  final bool accepted;
  final bool duplicate;

  static PurchaseVerificationResult parse(Object? value) {
    if (value is! Map ||
        value.length != 2 ||
        value['accepted'] != true ||
        value['duplicate'] is! bool) {
      throw const PurchaseRejectedException(
        'verification response must be {accepted: true, duplicate: bool}',
      );
    }
    return PurchaseVerificationResult(
      accepted: true,
      duplicate: value['duplicate'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PurchaseVerificationResult &&
      accepted == other.accepted &&
      duplicate == other.duplicate;

  @override
  int get hashCode => Object.hash(accepted, duplicate);
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
    return parseWallet(row);
  }

  @override
  Future<PurchaseVerificationResult> verifyPurchase({
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
      return PurchaseVerificationResult.parse(response.data);
    } on FunctionException catch (error) {
      throw PurchaseRejectedException(error.toString());
    }
  }

  static PremiumWallet parseWallet(Map<String, dynamic> row) => PremiumWallet(
    balance: _integer(row['royal_jade']),
    debt: _integer(row['royal_jade_debt']),
    version: _integer(row['version']),
  );

  static int _integer(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw const FormatException('wallet field is not an integer');
  }
}
