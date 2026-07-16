import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/backend_config.dart';
import 'package:pixel_survivor/backend/economy/premium_wallet.dart';
import 'package:pixel_survivor/backend/economy/purchase_gateway.dart';
import 'package:pixel_survivor/backend/progress/cloud_progress_repository.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  group('BackendConfig', () {
    test('missing environment values disable offline-safe backend use', () {
      expect(BackendConfig.fromEnvironment(), const BackendConfig.disabled());
      expect(BackendConfig.fromEnvironment().enabled, isFalse);
    });
  });

  group('AccountSession', () {
    test('signed-out state is not authenticated or permanent', () {
      const session = AccountSession.signedOut();

      expect(session.userId, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(session.isAnonymous, isFalse);
      expect(session.isPermanent, isFalse);
    });

    test('anonymous state requires a non-empty user ID', () {
      expect(() => AccountSession.anonymous(userId: ''), throwsArgumentError);
      expect(() => AccountSession.anonymous(userId: '  '), throwsArgumentError);

      final session = AccountSession.anonymous(userId: 'guest-1');
      expect(session.isAuthenticated, isTrue);
      expect(session.isAnonymous, isTrue);
      expect(session.isPermanent, isFalse);
    });

    test('permanent state requires Google identity data', () {
      expect(
        () => AccountSession.google(userId: '', email: 'user@example.com'),
        throwsArgumentError,
      );
      expect(
        () => AccountSession.google(userId: 'user-1', email: ''),
        throwsArgumentError,
      );

      final session = AccountSession.google(
        userId: 'user-1',
        email: 'user@example.com',
      );
      expect(session.isAuthenticated, isTrue);
      expect(session.isAnonymous, isFalse);
      expect(session.isPermanent, isTrue);
    });

    test('equal account values have structural equality', () {
      expect(
        AccountSession.google(userId: 'user-1', email: 'user@example.com'),
        AccountSession.google(userId: 'user-1', email: 'user@example.com'),
      );
      expect(
        AccountSession.anonymous(userId: 'guest-1').hashCode,
        AccountSession.anonymous(userId: 'guest-1').hashCode,
      );
    });
  });

  group('cloud progress', () {
    test('snapshot requires a positive server revision', () {
      expect(
        () => CloudProgressSnapshot(revision: -1, save: SaveState.defaults()),
        throwsArgumentError,
      );
      expect(
        () => CloudProgressSnapshot(revision: 0, save: SaveState.defaults()),
        throwsArgumentError,
      );
    });

    test(
      'repository update accepts the brief-specified revision int',
      () async {
        final repository = _RecordingCloudProgressRepository();

        await repository.update(
          save: SaveState.defaults(),
          expectedRevision: 7,
        );

        expect(repository.expectedRevision, 7);
      },
    );

    test('cloud snapshot carries the server revision and SaveState', () {
      final snapshot = CloudProgressSnapshot(
        revision: 7,
        save: SaveState.defaults(),
      );

      expect(snapshot.revision, 7);
      expect(snapshot.save.schemaVersion, SaveState.currentSchemaVersion);
    });

    test('sync result distinguishes updated and conflict snapshots', () {
      final snapshot = CloudProgressSnapshot(
        revision: 7,
        save: SaveState.defaults(),
      );

      expect(CloudSyncResult.updated(snapshot).hasConflict, isFalse);
      expect(CloudSyncResult.conflict(snapshot).hasConflict, isTrue);
      expect(
        CloudSyncResult.updated(snapshot),
        CloudSyncResult.updated(snapshot),
      );
    });

    test('equal progress values have structural equality', () {
      final first = CloudProgressSnapshot(
        revision: 2,
        save: SaveState.defaults(),
      );
      final second = CloudProgressSnapshot(
        revision: 2,
        save: SaveState.defaults(),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('progress equality ignores nested map insertion order', () {
      final first = CloudProgressSnapshot(
        revision: 2,
        save: SaveState.defaults().copyWith(
          characterVictoryCounts: {'second': 2, 'first': 1},
        ),
      );
      final second = CloudProgressSnapshot(
        revision: 2,
        save: SaveState.defaults().copyWith(
          characterVictoryCounts: {'first': 1, 'second': 2},
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('premium economy', () {
    test('paid wallet cannot be represented with negative values', () {
      expect(
        () => PremiumWallet(balance: -1, debt: 0, version: 0),
        throwsArgumentError,
      );
      expect(
        () => PremiumWallet(balance: 0, debt: -1, version: 0),
        throwsArgumentError,
      );
      expect(
        () => PremiumWallet(balance: 0, debt: 0, version: -1),
        throwsArgumentError,
      );
    });

    test('catalog exposes exactly the three approved product IDs', () {
      expect(PremiumProduct.ids, {
        'royal_jade_small',
        'royal_jade_medium',
        'royal_jade_large',
      });
    });

    test('purchase lifecycle validates status-specific data', () {
      expect(
        () => PurchaseUpdate.purchased(
          productId: PremiumProduct.smallId,
          purchaseToken: '',
        ),
        throwsArgumentError,
      );
      expect(
        PurchaseUpdate.pending(
          productId: PremiumProduct.smallId,
        ).requiresCompletion,
        isFalse,
      );
      expect(
        PurchaseUpdate.purchased(
          productId: PremiumProduct.smallId,
          purchaseToken: 'token-1',
        ).requiresCompletion,
        isTrue,
      );
      expect(
        () => PurchaseUpdate.error(
          productId: PremiumProduct.smallId,
          message: '',
        ),
        throwsArgumentError,
      );
    });

    test('gateway exposes unfinished purchase recovery', () async {
      final gateway = _RecordingPurchaseGateway();

      await gateway.recoverUnfinishedPurchases();

      expect(gateway.recoveryCount, 1);
    });

    test('equal economy values have structural equality', () {
      expect(
        PremiumWallet(balance: 10, debt: 2, version: 3),
        PremiumWallet(balance: 10, debt: 2, version: 3),
      );
      expect(
        const PremiumProduct(
          id: PremiumProduct.smallId,
          title: 'Small',
          description: '100',
          price: r'$0.99',
        ),
        const PremiumProduct(
          id: PremiumProduct.smallId,
          title: 'Small',
          description: '100',
          price: r'$0.99',
        ),
      );
      expect(
        PurchaseUpdate.purchased(
          productId: PremiumProduct.smallId,
          purchaseToken: 'token-1',
        ),
        PurchaseUpdate.purchased(
          productId: PremiumProduct.smallId,
          purchaseToken: 'token-1',
        ),
      );
    });
  });
}

class _RecordingPurchaseGateway implements PurchaseGateway {
  int recoveryCount = 0;

  @override
  Stream<PurchaseUpdate> get updates => const Stream.empty();

  @override
  Future<void> complete(PurchaseUpdate purchase) async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<PremiumProduct>> loadProducts(Set<String> productIds) async => [];

  @override
  Future<void> purchase(PremiumProduct product) async {}

  @override
  Future<void> recoverUnfinishedPurchases() async {
    recoveryCount += 1;
  }
}

class _RecordingCloudProgressRepository implements CloudProgressRepository {
  int? expectedRevision;

  @override
  Future<CloudProgressSnapshot> create(SaveState save) async =>
      CloudProgressSnapshot(revision: 1, save: save);

  @override
  Future<CloudProgressSnapshot?> fetch() async => null;

  @override
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  }) async {
    this.expectedRevision = expectedRevision;
    return CloudSyncResult.updated(
      CloudProgressSnapshot(revision: expectedRevision + 1, save: save),
    );
  }
}
