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
}

enum PurchaseStatus { pending, purchased, canceled, error }

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    this.purchaseToken,
    this.errorMessage,
  });

  final String productId;
  final PurchaseStatus status;
  final String? purchaseToken;
  final String? errorMessage;
}

abstract interface class PurchaseGateway {
  Stream<PurchaseUpdate> get updates;
  Future<bool> isAvailable();
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds);
  Future<void> purchase(PremiumProduct product);
  Future<void> complete(PurchaseUpdate purchase);
}
