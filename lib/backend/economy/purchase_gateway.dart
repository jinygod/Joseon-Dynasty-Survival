class PremiumProduct {
  const PremiumProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  static const smallId = 'royal_jade_small';
  static const mediumId = 'royal_jade_medium';
  static const largeId = 'royal_jade_large';
  static const ids = {smallId, mediumId, largeId};

  final String id;
  final String title;
  final String description;
  final String price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumProduct &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, title, description, price);
}

enum PurchaseStatus { pending, purchased, canceled, error }

class PurchaseUpdate {
  const PurchaseUpdate._({
    required this.productId,
    required this.status,
    this.purchaseToken,
    this.errorMessage,
  });

  factory PurchaseUpdate.pending({required String productId}) =>
      PurchaseUpdate._(
        productId: _requireNonEmpty('productId', productId),
        status: PurchaseStatus.pending,
      );

  factory PurchaseUpdate.purchased({
    required String productId,
    required String purchaseToken,
  }) => PurchaseUpdate._(
    productId: _requireNonEmpty('productId', productId),
    status: PurchaseStatus.purchased,
    purchaseToken: _requireNonEmpty('purchaseToken', purchaseToken),
  );

  factory PurchaseUpdate.canceled({required String productId}) =>
      PurchaseUpdate._(
        productId: _requireNonEmpty('productId', productId),
        status: PurchaseStatus.canceled,
      );

  factory PurchaseUpdate.error({
    required String productId,
    required String message,
  }) => PurchaseUpdate._(
    productId: _requireNonEmpty('productId', productId),
    status: PurchaseStatus.error,
    errorMessage: _requireNonEmpty('message', message),
  );

  final String productId;
  final PurchaseStatus status;
  final String? purchaseToken;
  final String? errorMessage;

  bool get requiresCompletion => status == PurchaseStatus.purchased;

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
      other is PurchaseUpdate &&
          productId == other.productId &&
          status == other.status &&
          purchaseToken == other.purchaseToken &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(productId, status, purchaseToken, errorMessage);
}

abstract interface class PurchaseGateway {
  Stream<PurchaseUpdate> get updates;
  Future<bool> isAvailable();
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds);
  Future<void> purchase(PremiumProduct product);
  Future<void> recoverUnfinishedPurchases();
  Future<void> complete(PurchaseUpdate purchase);
}
