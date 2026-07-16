import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';
import 'package:pixel_survivor/app/premium_shop_screen.dart';
import 'package:pixel_survivor/backend/account/account_service.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/backend_config.dart';
import 'package:pixel_survivor/backend/economy/premium_wallet.dart';
import 'package:pixel_survivor/backend/economy/purchase_controller.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';
import 'package:pixel_survivor/backend/economy/purchase_retry_store.dart';
import 'package:pixel_survivor/backend/economy/supabase_economy_repository.dart';
import 'package:pixel_survivor/backend/progress/cloud_progress_repository.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'resume retries a transient Play store initialization failure',
    () async {
      final gateway = _RecoveringGateway();
      final account = AccountSession.google(
        userId: 'account-a',
        email: 'player@example.com',
      );
      final purchases = PurchaseController(
        gateway: gateway,
        repository: _WalletRepository(),
        retryStore: _EmptyRetryStore(),
        sessionProvider: () => account,
        packageName: 'com.pixel.survivor.pixel_survivor',
      );

      await purchases.start();
      expect(purchases.state.storeStatus, PurchaseStoreStatus.unavailable);
      await purchases.onResume();
      expect(purchases.state.storeStatus, PurchaseStoreStatus.ready);
      expect(gateway.availabilityChecks, 2);
      purchases.dispose();
    },
  );

  testWidgets('production composition initializes account sync and purchases', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final account = AccountSession.google(
      userId: 'account-a',
      email: 'player@example.com',
    );
    final purchases = PurchaseController(
      gateway: _ReadyGateway(),
      repository: _WalletRepository(),
      retryStore: _EmptyRetryStore(),
      sessionProvider: () => account,
      packageName: 'com.pixel.survivor.pixel_survivor',
    );

    await tester.pumpWidget(
      PixelSurvivorApp(
        backendConfig: const BackendConfig(
          url: 'https://example.supabase.co',
          publishableKey: 'test-publishable-key',
        ),
        accountService: _PermanentAccountService(account),
        purchaseController: purchases,
        saveStore: _MemorySaveStore(),
        cloudProgressRepository: _MemoryCloudProgressRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('금옥 100'), findsOneWidget);
    expect(find.byKey(const Key('lobby-premium-shop')), findsOneWidget);
    expect(find.textContaining('player@example.com'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    purchases.dispose();
  });

  testWidgets('permanent account sees its server wallet and opens the shop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final account = AccountSession.google(
      userId: 'account-a',
      email: 'player@example.com',
    );
    final purchases = PurchaseController(
      gateway: _ReadyGateway(),
      repository: _WalletRepository(),
      retryStore: _EmptyRetryStore(),
      sessionProvider: () => account,
      packageName: 'com.pixel.survivor.pixel_survivor',
    );
    await purchases.start();
    final lobby = LobbyController(store: _MemorySaveStore());
    await lobby.load();

    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: AudioSettingsController(
            store: AudioSettingsRepository(),
          ),
          purchaseController: purchases,
        ),
      ),
    );

    expect(find.text('금옥 100'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lobby-premium-shop')));
    await tester.pumpAndSettle();
    expect(find.byType(PremiumShopScreen), findsOneWidget);
    expect(
      find.byKey(const Key('premium-buy-royal_jade_small')),
      findsOneWidget,
    );

    purchases.dispose();
    lobby.dispose();
  });

  testWidgets('purchase initialization failure stays visible and retryable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final lobby = LobbyController(store: _MemorySaveStore());
    await lobby.load();
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: AudioSettingsController(
            store: AudioSettingsRepository(),
          ),
          onPurchaseInitializationRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('금옥 재시도'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lobby-premium-shop-retry')));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
    lobby.dispose();
  });
}

class _ReadyGateway implements PurchaseGateway {
  @override
  Stream<PurchaseUpdate> get updates => const Stream.empty();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds) async => [
    const PremiumProduct(
      id: PremiumProduct.smallId,
      title: '금옥 한 줌',
      description: '금옥 100개',
      price: '₩1,100',
    ),
    const PremiumProduct(
      id: PremiumProduct.mediumId,
      title: '금옥 주머니',
      description: '금옥 550개',
      price: '₩5,500',
    ),
    const PremiumProduct(
      id: PremiumProduct.largeId,
      title: '금옥 궤짝',
      description: '금옥 1200개',
      price: '₩11,000',
    ),
  ];

  @override
  Future<void> purchase(
    PremiumProduct product, {
    required String applicationUserName,
  }) async {}

  @override
  Future<void> recoverUnfinishedPurchases({
    String? applicationUserName,
  }) async {}

  @override
  Future<void> complete(PurchaseUpdate purchase) async {}
}

class _RecoveringGateway extends _ReadyGateway {
  int availabilityChecks = 0;

  @override
  Future<bool> isAvailable() async => ++availabilityChecks > 1;
}

class _WalletRepository implements EconomyRepository {
  @override
  Future<PremiumWallet> fetchWallet() async =>
      PremiumWallet(balance: 100, debt: 0, version: 1);

  @override
  Future<PurchaseVerificationResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    required String packageName,
  }) async =>
      const PurchaseVerificationResult(accepted: true, duplicate: false);
}

class _EmptyRetryStore implements PurchaseRetryStore {
  @override
  Future<Set<PendingPurchase>> load() async => {};

  @override
  Future<void> put(PendingPurchase purchase) async {}

  @override
  Future<void> remove(String purchaseToken) async {}
}

class _MemorySaveStore implements SaveStore {
  SaveState value = SaveState.defaults();

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async => value = state;
}

class _PermanentAccountService implements AccountService {
  _PermanentAccountService(this.session);

  final AccountSession session;

  @override
  Stream<AccountSession> get changes => const Stream.empty();

  @override
  AccountSession get current => session;

  @override
  Future<AccountSession> ensureGuest() async => session;

  @override
  Future<AccountSession> connectGoogle() async => session;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteAccount() async {}
}

class _MemoryCloudProgressRepository implements CloudProgressRepository {
  CloudProgressSnapshot? snapshot;

  @override
  Future<CloudProgressSnapshot?> fetch() async => snapshot;

  @override
  Future<CloudProgressSnapshot> create(SaveState save) async =>
      snapshot = CloudProgressSnapshot(revision: 1, save: save);

  @override
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  }) async {
    final next = CloudProgressSnapshot(
      revision: expectedRevision + 1,
      save: save,
    );
    snapshot = next;
    return CloudSyncResult.updated(next);
  }
}
