import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'purchase_gateway.dart';

class PendingPurchase {
  const PendingPurchase({
    required this.ownerUserId,
    required this.productId,
    required this.purchaseToken,
  });

  final String ownerUserId;
  final String productId;
  final String purchaseToken;

  Map<String, String> toJson() => {
    'ownerUserId': ownerUserId,
    'productId': productId,
    'purchaseToken': purchaseToken,
  };

  static PendingPurchase? tryParse(String source) {
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic>) return null;
      final ownerUserId = value['ownerUserId'];
      final productId = value['productId'];
      final token = value['purchaseToken'];
      if (ownerUserId is! String ||
          ownerUserId.trim().isEmpty ||
          productId is! String ||
          !PremiumProduct.ids.contains(productId) ||
          token is! String ||
          token.trim().isEmpty) {
        return null;
      }
      return PendingPurchase(
        ownerUserId: ownerUserId.trim(),
        productId: productId,
        purchaseToken: token.trim(),
      );
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

abstract interface class PurchasePreferences {
  List<String>? getStringList(String key);
  Future<bool> setStringList(String key, List<String> value);
}

class PurchasePersistenceException implements Exception {
  const PurchasePersistenceException(this.message);
  final String message;

  @override
  String toString() => 'PurchasePersistenceException: $message';
}

class PurchaseOwnershipException implements Exception {
  const PurchaseOwnershipException(this.purchaseToken);
  final String purchaseToken;

  @override
  String toString() => 'PurchaseOwnershipException: $purchaseToken';
}

class SharedPreferencesPurchaseRetryStore implements PurchaseRetryStore {
  SharedPreferencesPurchaseRetryStore(SharedPreferences preferences)
    : _preferences = _SharedPreferencesAdapter(preferences);

  SharedPreferencesPurchaseRetryStore.withPreferences(this._preferences);

  static const storageKey = 'premium_purchase_retry_queue_v1';
  final PurchasePreferences _preferences;
  Future<void> _operationTail = Future.value();

  @override
  Future<Set<PendingPurchase>> load() => _serialize(_read);

  @override
  Future<void> put(PendingPurchase purchase) => _serialize(() async {
    final entries = _read();
    final existing = entries.lookup(purchase);
    if (existing != null &&
        (existing.ownerUserId != purchase.ownerUserId ||
            existing.productId != purchase.productId)) {
      throw PurchaseOwnershipException(purchase.purchaseToken);
    }
    entries.remove(purchase);
    entries.add(purchase);
    await _write(entries);
  });

  @override
  Future<void> remove(String purchaseToken) => _serialize(() async {
    final entries = _read()
      ..removeWhere((entry) => entry.purchaseToken == purchaseToken);
    await _write(entries);
  });

  Set<PendingPurchase> _read() {
    final result = <PendingPurchase>{};
    for (final source in _preferences.getStringList(storageKey) ?? const []) {
      final purchase = PendingPurchase.tryParse(source);
      if (purchase != null) result.add(purchase);
    }
    return result;
  }

  Future<void> _write(Set<PendingPurchase> entries) async {
    final values =
        (entries.toList()
              ..sort((a, b) => a.purchaseToken.compareTo(b.purchaseToken)))
            .map((entry) => jsonEncode(entry.toJson()))
            .toList();
    if (!await _preferences.setStringList(storageKey, values)) {
      throw const PurchasePersistenceException(
        'SharedPreferences rejected the retry queue write',
      );
    }
  }

  Future<T> _serialize<T>(FutureOr<T> Function() action) {
    final result = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

class _SharedPreferencesAdapter implements PurchasePreferences {
  _SharedPreferencesAdapter(this._preferences);
  final SharedPreferences _preferences;

  @override
  List<String>? getStringList(String key) => _preferences.getStringList(key);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);
}
