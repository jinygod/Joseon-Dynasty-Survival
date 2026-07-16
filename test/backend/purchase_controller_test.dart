import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/economy/premium_wallet.dart';
import 'package:pixel_survivor/backend/economy/purchase_controller.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';
import 'package:pixel_survivor/backend/economy/purchase_retry_store.dart';
import 'package:pixel_survivor/backend/economy/supabase_economy_repository.dart';

void main() {
  const products = [
    PremiumProduct(
      id: PremiumProduct.smallId,
      title: 'Small',
      description: '100',
      price: '₩1,100',
    ),
    PremiumProduct(
      id: PremiumProduct.mediumId,
      title: 'Medium',
      description: '550',
      price: r'$4.99',
    ),
    PremiumProduct(
      id: PremiumProduct.largeId,
      title: 'Large',
      description: '1200',
      price: '€8,99',
    ),
  ];

  PurchaseController buildController({
    required FakePurchaseGateway gateway,
    required FakeEconomyRepository repository,
    required FakeRetryStore retryStore,
    AccountSession session = const AccountSession.signedOut(),
    Duration verificationTimeout = const Duration(seconds: 2),
  }) => PurchaseController(
    gateway: gateway,
    repository: repository,
    retryStore: retryStore,
    sessionProvider: () => session,
    packageName: 'com.pixel.survivor.pixel_survivor',
    verificationTimeout: verificationTimeout,
  );

  test(
    'start subscribes once, queries exact IDs, and loads localized products',
    () async {
      final gateway = FakePurchaseGateway(products: products);
      final controller = buildController(
        gateway: gateway,
        repository: FakeEconomyRepository(),
        retryStore: FakeRetryStore(),
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );

      await controller.start();
      await controller.start();

      expect(gateway.updateListenerCount, 1);
      expect(gateway.requestedProductIds, PremiumProduct.ids);
      expect(controller.state.products.map((p) => p.price), [
        '₩1,100',
        r'$4.99',
        '€8,99',
      ]);
      expect(controller.state.storeStatus, PurchaseStoreStatus.ready);
      controller.dispose();
    },
  );

  test('unavailable store and query failures are visible states', () async {
    final unavailable = FakePurchaseGateway(available: false);
    final first = buildController(
      gateway: unavailable,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
    );
    await first.start();
    expect(first.state.storeStatus, PurchaseStoreStatus.unavailable);
    expect(unavailable.loadProductsCount, 0);
    first.dispose();

    final failed = FakePurchaseGateway(loadError: StateError('catalog down'));
    final second = buildController(
      gateway: failed,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
    );
    await second.start();
    expect(second.state.storeStatus, PurchaseStoreStatus.error);
    second.dispose();
  });

  test('guest purchase is rejected without opening billing', () async {
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
      session: AccountSession.anonymous(userId: 'guest'),
    );
    await controller.start();

    final result = await controller.purchase(products.first);

    expect(result, PurchaseStartResult.accountRequired);
    expect(gateway.purchases, isEmpty);
    controller.dispose();
  });

  test(
    'pending, canceled, and error callbacks never verify or grant',
    () async {
      final gateway = FakePurchaseGateway(products: products);
      final repository = FakeEconomyRepository();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: FakeRetryStore(),
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );
      await controller.start();

      gateway.emit(PurchaseUpdate.pending(productId: PremiumProduct.smallId));
      await flushEvents();
      expect(controller.state.pendingProductIds, {PremiumProduct.smallId});
      expect(repository.verifiedTokens, isEmpty);

      gateway.emit(PurchaseUpdate.canceled(productId: PremiumProduct.smallId));
      gateway.emit(
        PurchaseUpdate.error(
          productId: PremiumProduct.mediumId,
          message: 'declined',
        ),
      );
      await flushEvents();
      expect(controller.state.pendingProductIds, isEmpty);
      expect(repository.verifiedTokens, isEmpty);
      expect(gateway.completed, isEmpty);
      controller.dispose();
    },
  );

  test(
    'token is durable before verification and completion follows acceptance',
    () async {
      final events = <String>[];
      final gateway = FakePurchaseGateway(products: products, events: events);
      final repository = FakeEconomyRepository(events: events);
      final retryStore = FakeRetryStore(events: events);
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );
      await controller.start();
      events.clear();

      gateway.emit(
        PurchaseUpdate.purchased(
          productId: PremiumProduct.smallId,
          purchaseToken: 'token-1',
        ),
      );
      await flushEvents();

      expect(events, [
        'retry.put:token-1',
        'repository.verify:token-1',
        'repository.wallet',
        'gateway.complete:token-1',
        'retry.remove:token-1',
      ]);
      expect(
        controller.state.wallet,
        PremiumWallet(balance: 100, debt: 0, version: 1),
      );
      expect(controller.state.walletStale, isFalse);
      controller.dispose();
    },
  );

  test(
    'verification timeout and server rejection remain retryable and incomplete',
    () async {
      for (final repository in [
        FakeEconomyRepository(verificationCompleter: Completer<void>()),
        FakeEconomyRepository(
          rejection: const PurchaseRejectedException('invalid'),
        ),
      ]) {
        final gateway = FakePurchaseGateway(products: products);
        final retryStore = FakeRetryStore();
        final controller = buildController(
          gateway: gateway,
          repository: repository,
          retryStore: retryStore,
          session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
          verificationTimeout: const Duration(milliseconds: 5),
        );
        await controller.start();
        gateway.emit(
          PurchaseUpdate.purchased(
            productId: PremiumProduct.smallId,
            purchaseToken: 'retry-token',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await flushEvents();

        expect(retryStore.entries, {
          const PendingPurchase(
            productId: PremiumProduct.smallId,
            purchaseToken: 'retry-token',
          ),
        });
        expect(controller.state.retryPending, isTrue);
        expect(gateway.completed, isEmpty);
        controller.dispose();
      }
    },
  );

  test(
    'startup and resume recover durable tokens and unfinished Play purchases',
    () async {
      final gateway = FakePurchaseGateway(products: products);
      final repository = FakeEconomyRepository();
      final retryStore = FakeRetryStore()
        ..entries.add(
          const PendingPurchase(
            productId: PremiumProduct.mediumId,
            purchaseToken: 'stored-token',
          ),
        );
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );

      await controller.start();
      await controller.resume();

      expect(repository.verifiedTokens, ['stored-token']);
      expect(gateway.recoveryCount, 2);
      expect(gateway.completed.single.purchaseToken, 'stored-token');
      controller.dispose();
    },
  );

  test(
    'duplicate purchased callbacks verify, grant, and complete once',
    () async {
      final gateway = FakePurchaseGateway(products: products);
      final repository = FakeEconomyRepository();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: FakeRetryStore(),
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );
      await controller.start();
      final update = PurchaseUpdate.purchased(
        productId: PremiumProduct.largeId,
        purchaseToken: 'duplicate-token',
      );

      gateway
        ..emit(update)
        ..emit(update);
      await flushEvents();

      expect(repository.verifiedTokens, ['duplicate-token']);
      expect(gateway.completed, [update]);
      controller.dispose();
    },
  );
}

Future<void> flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    this.available = true,
    this.products = const [],
    this.loadError,
    this.events,
  });

  final bool available;
  final List<PremiumProduct> products;
  final Object? loadError;
  final List<String>? events;
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  int updateListenerCount = 0;
  int loadProductsCount = 0;
  int recoveryCount = 0;
  Set<String>? requestedProductIds;
  final purchases = <PremiumProduct>[];
  final completed = <PurchaseUpdate>[];

  void emit(PurchaseUpdate update) => _updates.add(update);

  @override
  Stream<PurchaseUpdate> get updates => Stream.multi((listener) {
    updateListenerCount += 1;
    final subscription = _updates.stream.listen(
      listener.addSync,
      onError: listener.addErrorSync,
      onDone: listener.closeSync,
    );
    listener.onCancel = subscription.cancel;
  }, isBroadcast: true);

  @override
  Future<void> complete(PurchaseUpdate purchase) async {
    events?.add('gateway.complete:${purchase.purchaseToken}');
    completed.add(purchase);
  }

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds) async {
    loadProductsCount += 1;
    requestedProductIds = Set.of(productIds);
    if (loadError case final error?) throw error;
    return products;
  }

  @override
  Future<void> purchase(PremiumProduct product) async => purchases.add(product);

  @override
  Future<void> recoverUnfinishedPurchases() async => recoveryCount += 1;
}

class FakeEconomyRepository implements EconomyRepository {
  FakeEconomyRepository({
    this.events,
    this.verificationCompleter,
    this.rejection,
  });

  final List<String>? events;
  final Completer<void>? verificationCompleter;
  final PurchaseRejectedException? rejection;
  final verifiedTokens = <String>[];
  var wallet = PremiumWallet(balance: 100, debt: 0, version: 1);

  @override
  Future<PremiumWallet> fetchWallet() async {
    events?.add('repository.wallet');
    return wallet;
  }

  @override
  Future<void> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    events?.add('repository.verify:$purchaseToken');
    verifiedTokens.add(purchaseToken);
    if (rejection case final error?) throw error;
    if (verificationCompleter case final completer?) await completer.future;
  }
}

class FakeRetryStore implements PurchaseRetryStore {
  FakeRetryStore({this.events});
  final List<String>? events;
  final entries = <PendingPurchase>{};

  @override
  Future<Set<PendingPurchase>> load() async => Set.of(entries);

  @override
  Future<void> put(PendingPurchase purchase) async {
    events?.add('retry.put:${purchase.purchaseToken}');
    entries.add(purchase);
  }

  @override
  Future<void> remove(String purchaseToken) async {
    events?.add('retry.remove:$purchaseToken');
    entries.removeWhere((entry) => entry.purchaseToken == purchaseToken);
  }
}
