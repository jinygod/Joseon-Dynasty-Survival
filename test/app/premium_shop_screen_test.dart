import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/premium_shop_screen.dart';
import 'package:pixel_survivor/app/premium_wallet_badge.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/economy/premium_wallet.dart';
import 'package:pixel_survivor/backend/economy/purchase_controller.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';
import 'package:pixel_survivor/backend/economy/purchase_retry_store.dart';
import 'package:pixel_survivor/backend/economy/supabase_economy_repository.dart';

void main() {
  testWidgets('shows only store-localized prices and fresh wallet', (
    tester,
  ) async {
    final gateway = ShopGateway();
    final controller = shopController(gateway: gateway);
    await controller.start();

    await tester.pumpWidget(
      MaterialApp(home: PremiumShopScreen(controller: controller)),
    );

    expect(find.text('금옥 100'), findsOneWidget);
    expect(find.text('₩1,100'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.text('€8,99'), findsOneWidget);
    expect(find.text(r'$0.99'), findsNothing);
    controller.dispose();
  });

  testWidgets('guest purchase opens account-link prompt', (tester) async {
    final gateway = ShopGateway();
    var prompts = 0;
    final controller = shopController(
      gateway: gateway,
      session: AccountSession.anonymous(userId: 'guest'),
    );
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(
        home: PremiumShopScreen(
          controller: controller,
          onAccountLinkRequired: () => prompts += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('premium-buy-royal_jade_small')));
    await tester.pump();

    expect(prompts, 1);
    expect(gateway.purchases, isEmpty);
    controller.dispose();
  });

  testWidgets('stale wallet and pending or retry states use required copy', (
    tester,
  ) async {
    final gateway = ShopGateway();
    final repository = ShopRepository()..walletError = StateError('offline');
    final controller = shopController(gateway: gateway, repository: repository);
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(home: PremiumShopScreen(controller: controller)),
    );

    expect(find.text('금옥 —'), findsOneWidget);
    gateway.emit(PurchaseUpdate.pending(productId: PremiumProduct.smallId));
    await tester.pump();
    expect(find.text('결제 승인 대기 중'), findsOneWidget);

    gateway.emit(
      PurchaseUpdate.purchased(
        productId: PremiumProduct.smallId,
        purchaseToken: 'retry-token',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('구매 확인 다시 시도'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('wallet badge exposes unavailable semantics when stale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PremiumWalletBadge(
            wallet: PremiumWallet(balance: 99, debt: 0, version: 1),
            stale: true,
          ),
        ),
      ),
    );
    expect(find.text('금옥 —'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(PremiumWalletBadge)),
      matchesSemantics(label: '금옥 잔액을 확인할 수 없음'),
    );
  });
}

PurchaseController shopController({
  required ShopGateway gateway,
  ShopRepository? repository,
  AccountSession? session,
}) => PurchaseController(
  gateway: gateway,
  repository: repository ?? ShopRepository(),
  retryStore: ShopRetryStore(),
  sessionProvider: () =>
      session ?? AccountSession.google(userId: 'u1', email: 'a@example.com'),
  packageName: 'com.pixel.survivor.pixel_survivor',
  verificationTimeout: const Duration(milliseconds: 1),
);

class ShopGateway implements PurchaseGateway {
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  final purchases = <PremiumProduct>[];

  void emit(PurchaseUpdate value) => _updates.add(value);

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;
  @override
  Future<void> complete(PurchaseUpdate purchase) async {}
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds) async =>
      const [
        PremiumProduct(
          id: PremiumProduct.smallId,
          title: '소형',
          description: '100 금옥',
          price: '₩1,100',
        ),
        PremiumProduct(
          id: PremiumProduct.mediumId,
          title: '중형',
          description: '550 금옥',
          price: r'$4.99',
        ),
        PremiumProduct(
          id: PremiumProduct.largeId,
          title: '대형',
          description: '1200 금옥',
          price: '€8,99',
        ),
      ];
  @override
  Future<void> purchase(PremiumProduct product) async => purchases.add(product);
  @override
  Future<void> recoverUnfinishedPurchases() async {}
}

class ShopRepository implements EconomyRepository {
  Object? walletError;
  @override
  Future<PremiumWallet> fetchWallet() async {
    if (walletError case final error?) throw error;
    return PremiumWallet(balance: 100, debt: 0, version: 1);
  }

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) => Completer<void>().future;
}

class ShopRetryStore implements PurchaseRetryStore {
  final entries = <PendingPurchase>{};
  @override
  Future<Set<PendingPurchase>> load() async => Set.of(entries);
  @override
  Future<void> put(PendingPurchase purchase) async => entries.add(purchase);
  @override
  Future<void> remove(String purchaseToken) async =>
      entries.removeWhere((entry) => entry.purchaseToken == purchaseToken);
}
