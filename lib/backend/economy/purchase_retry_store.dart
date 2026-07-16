import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_gateway.dart';

class PendingPurchase {
  const PendingPurchase({required this.productId, required this.purchaseToken});

  final String productId;
  final String purchaseToken;

  Map<String, String> toJson() => {
    'productId': productId,
    'purchaseToken': purchaseToken,
  };

  static PendingPurchase? tryParse(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) return null;
      final productId = value['productId'];
      final token = value['purchaseToken'];
      if (productId is! String ||
          !PremiumProduct.ids.contains(productId) ||
          token is! String ||
          token.trim().isEmpty) {
        return null;
      }
      return PendingPurchase(productId: productId, purchaseToken: token.trim());
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PendingPurchase && purchaseToken == other.purchaseToken;

  @override
  int get hashCode => purchaseToken.hashCode;
}

abstract interface class PurchaseRetryStore {
  Future<Set<PendingPurchase>> load();
  Future<void> put(PendingPurchase purchase);
  Future<void> remove(String purchaseToken);
}

class SharedPreferencesPurchaseRetryStore implements PurchaseRetryStore {
  SharedPreferencesPurchaseRetryStore(this._preferences);

  static const storageKey = 'premium_purchase_retry_queue_v1';
  final SharedPreferences _preferences;

  @override
  Future<Set<PendingPurchase>> load() async {
    final result = <PendingPurchase>{};
    for (final source in _preferences.getStringList(storageKey) ?? const []) {
      final purchase = PendingPurchase.tryParse(source);
      if (purchase != null) result.add(purchase);
    }
    return result;
  }

  @override
  Future<void> put(PendingPurchase purchase) async {
    final entries = await load();
    entries.remove(purchase);
    entries.add(purchase);
    await _write(entries);
  }

  @override
  Future<void> remove(String purchaseToken) async {
    final entries = await load()
      ..removeWhere((entry) => entry.purchaseToken == purchaseToken);
    await _write(entries);
  }

  Future<void> _write(Set<PendingPurchase> entries) =>
      _preferences.setStringList(
        storageKey,
        (entries.toList()
              ..sort((a, b) => a.purchaseToken.compareTo(b.purchaseToken)))
            .map((entry) => jsonEncode(entry.toJson()))
            .toList(),
      );
}
