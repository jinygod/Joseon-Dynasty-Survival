// Named public constructor arguments intentionally initialize private fields.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../account/account_session.dart';
import 'premium_wallet.dart';
import 'purchase_gateway.dart';
import 'purchase_retry_store.dart';
import 'supabase_economy_repository.dart';

enum PurchaseStoreStatus { loading, ready, unavailable, error }

enum PurchaseStartResult { started, accountRequired, unavailable, error }

class PurchaseState {
  const PurchaseState({
    this.storeStatus = PurchaseStoreStatus.loading,
    this.products = const [],
    this.wallet,
    this.walletStale = true,
    this.pendingProductCounts = const {},
    this.inFlightProductIds = const {},
    this.retryPending = false,
    this.accountLinkRequired = false,
    this.message,
  });

  final PurchaseStoreStatus storeStatus;
  final List<PremiumProduct> products;
  final PremiumWallet? wallet;
  final bool walletStale;
  final Map<String, int> pendingProductCounts;
  final Set<String> inFlightProductIds;
  final bool retryPending;
  final bool accountLinkRequired;
  final String? message;

  Set<String> get pendingProductIds => pendingProductCounts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toSet();

  PurchaseState copyWith({
    PurchaseStoreStatus? storeStatus,
    List<PremiumProduct>? products,
    PremiumWallet? wallet,
    bool? walletStale,
    Map<String, int>? pendingProductCounts,
    Set<String>? inFlightProductIds,
    bool? retryPending,
    bool? accountLinkRequired,
    String? message,
    bool clearWallet = false,
  }) => PurchaseState(
    storeStatus: storeStatus ?? this.storeStatus,
    products: products ?? this.products,
    wallet: clearWallet ? null : wallet ?? this.wallet,
    walletStale: walletStale ?? this.walletStale,
    pendingProductCounts: pendingProductCounts ?? this.pendingProductCounts,
    inFlightProductIds: inFlightProductIds ?? this.inFlightProductIds,
    retryPending: retryPending ?? this.retryPending,
    accountLinkRequired: accountLinkRequired ?? this.accountLinkRequired,
    message: message ?? this.message,
  );
}

class PurchaseController extends ChangeNotifier {
  PurchaseController({
    required PurchaseGateway gateway,
    required EconomyRepository repository,
    required PurchaseRetryStore retryStore,
    required AccountSession Function() sessionProvider,
    required String packageName,
    this.verificationTimeout = const Duration(seconds: 15),
  }) : _gateway = gateway,
       _repository = repository,
       _retryStore = retryStore,
       _sessionProvider = sessionProvider,
       _packageName = packageName;

  final PurchaseGateway _gateway;
  final EconomyRepository _repository;
  final PurchaseRetryStore _retryStore;
  final AccountSession Function() _sessionProvider;
  final String _packageName;
  final Duration verificationTimeout;
  StreamSubscription<PurchaseUpdate>? _subscription;
  final _processingTokens = <String>{};
  final _processingCompletions = <String, Completer<void>>{};
  final _completedTokens = <String>{};
  final _disposeSignal = Completer<void>();
  int _accountGeneration = 0;
  bool _initialized = false;
  bool _disposed = false;
  PurchaseState _state = const PurchaseState();

  PurchaseState get state => _state;

  Future<void> onStartup() => start();
  Future<void> onResume() => onAccountChanged(_sessionProvider());

  Future<void> onAccountChanged(AccountSession session) =>
      _applyAccountChanged(session, propagateRecoveryError: false);

  Future<void> start() async {
    if (_disposed || _initialized) return;
    _subscription ??= _gateway.updates.listen(
      _handleUpdate,
      onError: _handleStreamError,
    );
    _setState(_state.copyWith(storeStatus: PurchaseStoreStatus.loading));
    try {
      final session = _sessionProvider();
      await _applyAccountChanged(session, propagateRecoveryError: true);
      if (_disposed) return;
      if (!await _gateway.isAvailable()) {
        _setState(
          _state.copyWith(
            storeStatus: PurchaseStoreStatus.unavailable,
            message: '스토어를 사용할 수 없습니다',
          ),
        );
        _initialized = true;
        return;
      }
      if (_disposed) return;
      final products = await _gateway.loadProducts(PremiumProduct.ids);
      if (_disposed) return;
      _setState(
        _state.copyWith(
          storeStatus: PurchaseStoreStatus.ready,
          products: List.unmodifiable(products),
        ),
      );
      _initialized = true;
    } catch (error) {
      _initialized = false;
      _setState(
        _state.copyWith(
          storeStatus: PurchaseStoreStatus.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> resume() async {
    await onResume();
  }

  Future<void> _applyAccountChanged(
    AccountSession session, {
    required bool propagateRecoveryError,
  }) async {
    if (_disposed) return;
    final generation = ++_accountGeneration;
    _setState(
      _state.copyWith(
        clearWallet: true,
        walletStale: true,
        pendingProductCounts: const {},
        inFlightProductIds: const {},
        retryPending: false,
        accountLinkRequired: !session.isPermanent,
      ),
    );
    if (!session.isPermanent) return;
    final ownerUserId = session.userId!;
    try {
      await _drainPurchaseProcessing();
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      await _gateway.recoverUnfinishedPurchases(
        applicationUserName: ownerUserId,
      );
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      await _refreshWallet(ownerUserId, generation: generation, strict: false);
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      await _retryDurablePurchases(ownerUserId, generation);
    } catch (error) {
      if (_isCurrentOwner(ownerUserId, generation)) {
        _setState(_state.copyWith(message: error.toString()));
      }
      if (propagateRecoveryError) rethrow;
    }
  }

  Future<PurchaseStartResult> purchase(PremiumProduct product) async {
    if (_disposed) return PurchaseStartResult.error;
    final session = _sessionProvider();
    if (!session.isPermanent) return PurchaseStartResult.accountRequired;
    if (_state.storeStatus != PurchaseStoreStatus.ready ||
        _state.walletStale ||
        _state.pendingProductIds.contains(product.id) ||
        _state.inFlightProductIds.contains(product.id)) {
      _setState(_state.copyWith(message: '현재 구매를 시작할 수 없습니다'));
      return PurchaseStartResult.unavailable;
    }
    final userId = session.userId!;
    _setInFlight(product.id, true);
    try {
      await _gateway.purchase(product, applicationUserName: userId);
      return _disposed
          ? PurchaseStartResult.error
          : PurchaseStartResult.started;
    } catch (error) {
      _setState(_state.copyWith(message: error.toString()));
      return PurchaseStartResult.error;
    } finally {
      _setInFlight(product.id, false);
    }
  }

  void _handleUpdate(PurchaseUpdate update) {
    final ownerUserId = update.ownerUserId;
    if (_disposed ||
        ownerUserId == null ||
        !PremiumProduct.ids.contains(update.productId)) {
      return;
    }
    final isCurrentOwner = _isCurrentOwner(ownerUserId);
    switch (update.status) {
      case PurchaseStatus.pending:
        if (isCurrentOwner) _changePending(update.productId, 1);
      case PurchaseStatus.canceled:
      case PurchaseStatus.error:
        if (isCurrentOwner) _changePending(update.productId, -1);
        if (isCurrentOwner && update.status == PurchaseStatus.error) {
          _setState(_state.copyWith(message: update.errorMessage));
        }
      case PurchaseStatus.purchased:
        if (isCurrentOwner) _changePending(update.productId, -1);
        unawaited(
          _processPurchased(
            update,
            ownerUserId: ownerUserId,
            generation: _accountGeneration,
          ),
        );
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    _setState(_state.copyWith(message: error.toString()));
  }

  Future<void> _retryDurablePurchases(
    String ownerUserId,
    int generation,
  ) async {
    final entries = await _retryStore.load();
    if (!_isCurrentOwner(ownerUserId, generation)) return;
    final ownerEntries = entries
        .where((entry) => entry.ownerUserId == ownerUserId)
        .toList();
    _setState(_state.copyWith(retryPending: ownerEntries.isNotEmpty));
    for (final entry in ownerEntries) {
      await _processPurchased(
        PurchaseUpdate.purchased(
          ownerUserId: entry.ownerUserId,
          productId: entry.productId,
          purchaseToken: entry.purchaseToken,
        ),
        ownerUserId: entry.ownerUserId,
        generation: generation,
        alreadyDurable: true,
      );
      if (!_isCurrentOwner(ownerUserId, generation)) return;
    }
  }

  Future<void> _processPurchased(
    PurchaseUpdate update, {
    required String ownerUserId,
    required int generation,
    bool alreadyDurable = false,
  }) async {
    final token = update.purchaseToken!;
    if (_disposed ||
        _completedTokens.contains(token) ||
        !_processingTokens.add(token)) {
      return;
    }
    final completion = Completer<void>();
    _processingCompletions[token] = completion;
    try {
      if (!alreadyDurable) {
        await _retryStore.put(
          PendingPurchase(
            ownerUserId: ownerUserId,
            productId: update.productId,
            purchaseToken: token,
          ),
        );
        final durableEntries = await _retryStore.load();
        if (_disposed ||
            !durableEntries.any(
              (entry) =>
                  entry.purchaseToken == token &&
                  entry.ownerUserId == ownerUserId &&
                  entry.productId == update.productId,
            )) {
          return;
        }
      }
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      _setState(_state.copyWith(retryPending: true));
      final result = await _repository
          .verifyPurchase(
            productId: update.productId,
            purchaseToken: token,
            packageName: _packageName,
          )
          .timeout(verificationTimeout);
      if (!result.accepted || !_isCurrentOwner(ownerUserId, generation)) return;
      await _refreshWallet(ownerUserId, generation: generation, strict: true);
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      await _gateway.complete(update);
      if (_disposed) return;
      await _retryStore.remove(token);
      if (_disposed) return;
      _completedTokens.add(token);
      final remaining = await _retryStore.load();
      if (_isCurrentOwner(ownerUserId, generation)) {
        _setState(
          _state.copyWith(
            retryPending: remaining.any(
              (entry) => entry.ownerUserId == ownerUserId,
            ),
          ),
        );
      }
    } catch (error) {
      if (_isCurrentOwner(ownerUserId, generation)) {
        _setState(
          _state.copyWith(retryPending: true, message: error.toString()),
        );
      }
    } finally {
      _processingTokens.remove(token);
      if (identical(_processingCompletions[token], completion)) {
        _processingCompletions.remove(token);
      }
      completion.complete();
    }
  }

  Future<void> _drainPurchaseProcessing() async {
    if (_disposed || _processingCompletions.isEmpty) return;
    final activeAtTransition = _processingCompletions.values
        .map((completion) => completion.future)
        .toList();
    await Future.any([Future.wait(activeAtTransition), _disposeSignal.future]);
  }

  Future<void> _refreshWallet(
    String ownerUserId, {
    required int generation,
    required bool strict,
  }) async {
    if (!_isCurrentOwner(ownerUserId, generation)) return;
    try {
      final wallet = await _repository.fetchWallet();
      if (!_isCurrentOwner(ownerUserId, generation)) return;
      _setState(_state.copyWith(wallet: wallet, walletStale: false));
    } catch (error) {
      if (_isCurrentOwner(ownerUserId, generation)) {
        _setState(
          _state.copyWith(walletStale: true, message: error.toString()),
        );
      }
      if (strict) rethrow;
    }
  }

  String? _currentPermanentUserId() {
    final session = _sessionProvider();
    return session.isPermanent ? session.userId : null;
  }

  bool _isCurrentOwner(String ownerUserId, [int? generation]) =>
      !_disposed &&
      (generation == null || generation == _accountGeneration) &&
      _currentPermanentUserId() == ownerUserId;

  void _changePending(String productId, int delta) {
    final counts = {..._state.pendingProductCounts};
    final next = (counts[productId] ?? 0) + delta;
    if (next <= 0) {
      counts.remove(productId);
    } else {
      counts[productId] = next;
    }
    _setState(_state.copyWith(pendingProductCounts: Map.unmodifiable(counts)));
  }

  void _setInFlight(String productId, bool inFlight) {
    final values = {..._state.inFlightProductIds};
    inFlight ? values.add(productId) : values.remove(productId);
    _setState(_state.copyWith(inFlightProductIds: Set.unmodifiable(values)));
  }

  void _setState(PurchaseState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_disposeSignal.isCompleted) _disposeSignal.complete();
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
