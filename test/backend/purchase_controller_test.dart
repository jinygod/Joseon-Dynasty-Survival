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
    AccountSession Function()? sessionProvider,
    Duration verificationTimeout = const Duration(seconds: 2),
  }) => PurchaseController(
    gateway: gateway,
    repository: repository,
    retryStore: retryStore,
    sessionProvider: sessionProvider ?? () => session,
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

      gateway.emit(
        PurchaseUpdate.pending(
          ownerUserId: 'u1',
          productId: PremiumProduct.smallId,
        ),
      );
      await flushEvents();
      expect(controller.state.pendingProductIds, {PremiumProduct.smallId});
      expect(repository.verifiedTokens, isEmpty);

      gateway.emit(
        PurchaseUpdate.canceled(
          ownerUserId: 'u1',
          productId: PremiumProduct.smallId,
        ),
      );
      gateway.emit(
        PurchaseUpdate.error(
          ownerUserId: 'u1',
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
          ownerUserId: 'u1',
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
            ownerUserId: 'u1',
            productId: PremiumProduct.smallId,
            purchaseToken: 'retry-token',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await flushEvents();

        expect(retryStore.entries, {
          const PendingPurchase(
            ownerUserId: 'u1',
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
            ownerUserId: 'u1',
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
        ownerUserId: 'u1',
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

  test(
    'durable purchases are never submitted under a different user',
    () async {
      final repository = FakeEconomyRepository();
      final retryStore = FakeRetryStore()
        ..entries.add(
          const PendingPurchase(
            ownerUserId: 'owner-a',
            productId: PremiumProduct.smallId,
            purchaseToken: 'owner-a-token',
          ),
        );
      final controller = buildController(
        gateway: FakePurchaseGateway(products: products),
        repository: repository,
        retryStore: retryStore,
        session: AccountSession.google(
          userId: 'owner-b',
          email: 'b@example.com',
        ),
      );
      await controller.start();
      expect(repository.verifiedTokens, isEmpty);
      expect(retryStore.entries.single.ownerUserId, 'owner-a');
      controller.dispose();
    },
  );

  test(
    'account switch during verification leaves Play and retry durable',
    () async {
      var session = AccountSession.google(
        userId: 'owner-a',
        email: 'a@example.com',
      );
      final verification = Completer<void>();
      final repository = FakeEconomyRepository(
        verificationCompleter: verification,
      );
      final gateway = FakePurchaseGateway(products: products);
      final retryStore = FakeRetryStore();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        sessionProvider: () => session,
      );
      await controller.start();
      gateway.emit(
        PurchaseUpdate.purchased(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'switch-token',
        ),
      );
      await flushEvents();
      session = AccountSession.google(
        userId: 'owner-b',
        email: 'b@example.com',
      );
      verification.complete();
      await flushEvents();
      expect(gateway.completed, isEmpty);
      expect(retryStore.entries.single.ownerUserId, 'owner-a');
      controller.dispose();
    },
  );

  test(
    'resume drains stale token work before retrying the current owner',
    () async {
      final session = AccountSession.google(
        userId: 'owner-a',
        email: 'a@example.com',
      );
      final firstVerification = Completer<void>();
      final repository = FakeEconomyRepository(
        verificationCompleters: [firstVerification],
      );
      final gateway = FakePurchaseGateway(products: products);
      final retryStore = FakeRetryStore();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        session: session,
      );
      await controller.start();
      gateway.emit(
        PurchaseUpdate.purchased(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'overlap-token',
        ),
      );
      await flushEvents();
      expect(repository.verifiedTokens, ['overlap-token']);

      var resumeCompleted = false;
      final resume = controller
          .onAccountChanged(session)
          .then((_) => resumeCompleted = true);
      await flushEvents();
      expect(resumeCompleted, isFalse);

      firstVerification.complete();
      await resume;

      expect(repository.verifiedTokens, ['overlap-token', 'overlap-token']);
      expect(gateway.completed.single.purchaseToken, 'overlap-token');
      expect(retryStore.entries, isEmpty);
      controller.dispose();
    },
  );

  test(
    'account switch drains a foreign callback put before owner retry',
    () async {
      var session = AccountSession.google(
        userId: 'owner-b',
        email: 'b@example.com',
      );
      final putStarted = Completer<void>();
      final releasePut = Completer<void>();
      final retryStore = FakeRetryStore(
        putStarted: putStarted,
        putCompleter: releasePut,
      );
      final repository = FakeEconomyRepository();
      final gateway = FakePurchaseGateway(products: products);
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        sessionProvider: () => session,
      );
      await controller.start();
      gateway.emit(
        PurchaseUpdate.purchased(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'foreign-put-token',
        ),
      );
      await putStarted.future;

      session = AccountSession.google(
        userId: 'owner-a',
        email: 'a@example.com',
      );
      var accountChangeCompleted = false;
      final accountChange = controller
          .onAccountChanged(session)
          .then((_) => accountChangeCompleted = true);
      await flushEvents();
      expect(accountChangeCompleted, isFalse);

      releasePut.complete();
      await accountChange;

      expect(repository.verifiedTokens, ['foreign-put-token']);
      expect(gateway.completed.single.purchaseToken, 'foreign-put-token');
      expect(retryStore.entries, isEmpty);
      controller.dispose();
    },
  );

  test('restored callback cannot reassign an existing token owner', () async {
    final repository = FakeEconomyRepository();
    final gateway = FakePurchaseGateway(products: products);
    final retryStore = FakeRetryStore()
      ..entries.add(
        const PendingPurchase(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'shared-token',
        ),
      );
    final controller = buildController(
      gateway: gateway,
      repository: repository,
      retryStore: retryStore,
      session: AccountSession.google(userId: 'owner-b', email: 'b@example.com'),
    );
    await controller.start();
    gateway.emit(
      PurchaseUpdate.purchased(
        ownerUserId: 'owner-a',
        productId: PremiumProduct.smallId,
        purchaseToken: 'shared-token',
      ),
    );
    await flushEvents();
    expect(repository.verifiedTokens, isEmpty);
    expect(retryStore.entries.single.ownerUserId, 'owner-a');
    controller.dispose();
  });

  test('persistence failure prevents server verification', () async {
    final repository = FakeEconomyRepository();
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: repository,
      retryStore: FakeRetryStore(putError: StateError('disk full')),
      session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
    );
    await controller.start();
    gateway.emit(
      PurchaseUpdate.purchased(
        ownerUserId: 'u1',
        productId: PremiumProduct.smallId,
        purchaseToken: 'not-durable',
      ),
    );
    await flushEvents();
    expect(repository.verifiedTokens, isEmpty);
    controller.dispose();
  });

  test(
    'wallet refresh failure leaves Play unfinished until resume succeeds',
    () async {
      final repository = FakeEconomyRepository();
      final gateway = FakePurchaseGateway(products: products);
      final retryStore = FakeRetryStore();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );
      await controller.start();
      repository.walletError = StateError('wallet offline');
      gateway.emit(
        PurchaseUpdate.purchased(
          ownerUserId: 'u1',
          productId: PremiumProduct.smallId,
          purchaseToken: 'wallet-token',
        ),
      );
      await flushEvents();
      expect(gateway.completed, isEmpty);
      expect(retryStore.entries, isNotEmpty);
      repository.walletError = null;
      await controller.onResume();
      expect(gateway.completed.single.purchaseToken, 'wallet-token');
      expect(retryStore.entries, isEmpty);
      controller.dispose();
    },
  );

  test('stream errors and malformed products are recoverable', () async {
    final gateway = FakePurchaseGateway(products: products);
    final repository = FakeEconomyRepository();
    final controller = buildController(
      gateway: gateway,
      repository: repository,
      retryStore: FakeRetryStore(),
      session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
    );
    await controller.start();
    gateway.emitError(StateError('billing stream down'));
    gateway.emit(
      PurchaseUpdate.purchased(
        ownerUserId: 'u1',
        productId: 'unknown',
        purchaseToken: 'bad',
      ),
    );
    gateway.emit(
      PurchaseUpdate.pending(
        ownerUserId: 'u1',
        productId: PremiumProduct.smallId,
      ),
    );
    await flushEvents();
    expect(controller.state.message, contains('billing stream down'));
    expect(repository.verifiedTokens, isEmpty);
    expect(controller.state.pendingProductCounts[PremiumProduct.smallId], 1);
    controller.dispose();
  });

  test('dispose during verification prevents completion', () async {
    final verification = Completer<void>();
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(verificationCompleter: verification),
      retryStore: FakeRetryStore(),
      session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
    );
    await controller.start();
    gateway.emit(
      PurchaseUpdate.purchased(
        ownerUserId: 'u1',
        productId: PremiumProduct.smallId,
        purchaseToken: 'dispose-token',
      ),
    );
    await flushEvents();
    controller.dispose();
    verification.complete();
    await flushEvents();
    expect(gateway.completed, isEmpty);
  });

  test(
    'failed recovery retries initialization without resubscribing',
    () async {
      final gateway = FakePurchaseGateway(
        products: products,
        recoveryErrors: [StateError('restore failed')],
      );
      final controller = buildController(
        gateway: gateway,
        repository: FakeEconomyRepository(),
        retryStore: FakeRetryStore(),
        session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
      );
      await controller.onStartup();
      expect(controller.state.storeStatus, PurchaseStoreStatus.error);
      await controller.onStartup();
      expect(controller.state.storeStatus, PurchaseStoreStatus.ready);
      expect(gateway.updateListenerCount, 1);
      controller.dispose();
    },
  );

  test('lifecycle API performs startup and resume recovery', () async {
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
      session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
    );
    await controller.onStartup();
    await controller.onResume();
    expect(gateway.recoveryCount, 2);
    controller.dispose();
  });

  test(
    'resume refreshes session and wallet after guest links Google',
    () async {
      var session = AccountSession.anonymous(userId: 'guest');
      final gateway = FakePurchaseGateway(products: products);
      final controller = buildController(
        gateway: gateway,
        repository: FakeEconomyRepository(),
        retryStore: FakeRetryStore(),
        sessionProvider: () => session,
      );
      await controller.onStartup();
      expect(controller.state.accountLinkRequired, isTrue);
      session = AccountSession.google(userId: 'u1', email: 'a@example.com');

      await controller.onResume();

      expect(controller.state.accountLinkRequired, isFalse);
      expect(controller.state.walletStale, isFalse);
      controller.dispose();
    },
  );

  test('multiple pending transactions for one product are counted', () async {
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
      session: AccountSession.google(userId: 'u1', email: 'a@example.com'),
    );
    await controller.start();
    gateway
      ..emit(
        PurchaseUpdate.pending(
          ownerUserId: 'u1',
          productId: PremiumProduct.smallId,
        ),
      )
      ..emit(
        PurchaseUpdate.pending(
          ownerUserId: 'u1',
          productId: PremiumProduct.smallId,
        ),
      );
    await flushEvents();
    expect(controller.state.pendingProductCounts[PremiumProduct.smallId], 2);
    gateway.emit(
      PurchaseUpdate.canceled(
        ownerUserId: 'u1',
        productId: PremiumProduct.smallId,
      ),
    );
    await flushEvents();
    expect(controller.state.pendingProductCounts[PremiumProduct.smallId], 1);
    controller.dispose();
  });

  test(
    'delayed owner A callback after switch to B is durable but not verified',
    () async {
      var session = AccountSession.google(userId: 'owner-a', email: 'a@test');
      final gateway = FakePurchaseGateway(products: products);
      final repository = FakeEconomyRepository();
      final retryStore = FakeRetryStore();
      final controller = buildController(
        gateway: gateway,
        repository: repository,
        retryStore: retryStore,
        sessionProvider: () => session,
      );
      await controller.start();
      session = AccountSession.google(userId: 'owner-b', email: 'b@test');
      await controller.onAccountChanged(session);
      gateway.emit(
        PurchaseUpdate.purchased(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'delayed-a',
        ),
      );
      await flushEvents();

      expect(repository.verifiedTokens, isEmpty);
      expect(retryStore.entries.single.ownerUserId, 'owner-a');
      controller.dispose();
    },
  );

  test('pending and retry state includes only the current owner', () async {
    final gateway = FakePurchaseGateway(products: products);
    final retryStore = FakeRetryStore()
      ..entries.add(
        const PendingPurchase(
          ownerUserId: 'owner-a',
          productId: PremiumProduct.smallId,
          purchaseToken: 'foreign-token',
        ),
      );
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(),
      retryStore: retryStore,
      session: AccountSession.google(userId: 'owner-b', email: 'b@test'),
    );
    await controller.start();
    expect(controller.state.retryPending, isFalse);
    gateway.emit(
      PurchaseUpdate.pending(
        ownerUserId: 'owner-a',
        productId: PremiumProduct.smallId,
      ),
    );
    await flushEvents();
    expect(controller.state.pendingProductCounts, isEmpty);
    gateway.emit(
      PurchaseUpdate.pending(
        ownerUserId: 'owner-b',
        productId: PremiumProduct.smallId,
      ),
    );
    await flushEvents();
    expect(controller.state.pendingProductCounts[PremiumProduct.smallId], 1);
    controller.dispose();
  });

  test('guest account change clears wallet and owner UI caches', () async {
    var session = AccountSession.google(userId: 'owner-a', email: 'a@test');
    final gateway = FakePurchaseGateway(products: products);
    final controller = buildController(
      gateway: gateway,
      repository: FakeEconomyRepository(),
      retryStore: FakeRetryStore(),
      sessionProvider: () => session,
    );
    await controller.start();
    gateway.emit(
      PurchaseUpdate.pending(
        ownerUserId: 'owner-a',
        productId: PremiumProduct.smallId,
      ),
    );
    await flushEvents();
    session = const AccountSession.signedOut();
    await controller.onAccountChanged(session);

    expect(controller.state.wallet, isNull);
    expect(controller.state.walletStale, isTrue);
    expect(controller.state.pendingProductCounts, isEmpty);
    expect(controller.state.retryPending, isFalse);
    controller.dispose();
  });

  test(
    'same product purchases bind each sequential account explicitly',
    () async {
      var session = AccountSession.google(userId: 'owner-a', email: 'a@test');
      final gateway = FakePurchaseGateway(products: products);
      final controller = buildController(
        gateway: gateway,
        repository: FakeEconomyRepository(),
        retryStore: FakeRetryStore(),
        sessionProvider: () => session,
      );
      await controller.start();
      await controller.purchase(products.first);
      session = AccountSession.google(userId: 'owner-b', email: 'b@test');
      await controller.onAccountChanged(session);
      await controller.purchase(products.first);

      expect(gateway.purchaseApplicationUserNames, ['owner-a', 'owner-b']);
      expect(gateway.recoveryApplicationUserNames, ['owner-a', 'owner-b']);
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
    this.recoveryErrors = const [],
  });

  final bool available;
  final List<PremiumProduct> products;
  final Object? loadError;
  final List<String>? events;
  final List<Object> recoveryErrors;
  final _updates = StreamController<PurchaseUpdate>.broadcast();
  int updateListenerCount = 0;
  int loadProductsCount = 0;
  int recoveryCount = 0;
  Set<String>? requestedProductIds;
  final purchases = <PremiumProduct>[];
  final purchaseApplicationUserNames = <String>[];
  final recoveryApplicationUserNames = <String>[];
  final completed = <PurchaseUpdate>[];

  void emit(PurchaseUpdate update) => _updates.add(update);
  void emitError(Object error) => _updates.addError(error);

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
  Future<void> purchase(
    PremiumProduct product, {
    required String applicationUserName,
  }) async {
    purchases.add(product);
    purchaseApplicationUserNames.add(applicationUserName);
  }

  @override
  Future<void> recoverUnfinishedPurchases({
    required String applicationUserName,
  }) async {
    recoveryApplicationUserNames.add(applicationUserName);
    final attempt = recoveryCount++;
    if (attempt < recoveryErrors.length) throw recoveryErrors[attempt];
  }
}

class FakeEconomyRepository implements EconomyRepository {
  FakeEconomyRepository({
    this.events,
    this.verificationCompleter,
    this.verificationCompleters = const [],
    this.rejection,
  });

  final List<String>? events;
  final Completer<void>? verificationCompleter;
  final List<Completer<void>> verificationCompleters;
  final PurchaseRejectedException? rejection;
  final verifiedTokens = <String>[];
  var wallet = PremiumWallet(balance: 100, debt: 0, version: 1);
  Object? walletError;

  @override
  Future<PremiumWallet> fetchWallet() async {
    events?.add('repository.wallet');
    if (walletError case final error?) throw error;
    return wallet;
  }

  @override
  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async {
    final callIndex = verifiedTokens.length;
    events?.add('repository.verify:$purchaseToken');
    verifiedTokens.add(purchaseToken);
    if (rejection case final error?) throw error;
    if (callIndex < verificationCompleters.length) {
      await verificationCompleters[callIndex].future;
    } else if (verificationCompleter case final completer?) {
      await completer.future;
    }
    return const PurchaseVerificationResult(accepted: true, duplicate: false);
  }
}

class FakeRetryStore implements PurchaseRetryStore {
  FakeRetryStore({
    this.events,
    this.putError,
    this.putStarted,
    this.putCompleter,
  });
  final List<String>? events;
  final Object? putError;
  final Completer<void>? putStarted;
  final Completer<void>? putCompleter;
  final entries = <PendingPurchase>{};

  @override
  Future<Set<PendingPurchase>> load() async => Set.of(entries);

  @override
  Future<void> put(PendingPurchase purchase) async {
    if (putError case final error?) throw error;
    if (putStarted case final started?) {
      if (!started.isCompleted) started.complete();
    }
    if (putCompleter case final completer?) await completer.future;
    events?.add('retry.put:${purchase.purchaseToken}');
    entries.add(purchase);
  }

  @override
  Future<void> remove(String purchaseToken) async {
    events?.add('retry.remove:$purchaseToken');
    entries.removeWhere((entry) => entry.purchaseToken == purchaseToken);
  }
}
