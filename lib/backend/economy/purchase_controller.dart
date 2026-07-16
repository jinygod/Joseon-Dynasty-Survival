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
    this.pendingProductIds = const {},
    this.retryPending = false,
    this.message,
  });

  final PurchaseStoreStatus storeStatus;
  final List<PremiumProduct> products;
  final PremiumWallet? wallet;
  final bool walletStale;
  final Set<String> pendingProductIds;
  final bool retryPending;
  final String? message;

  PurchaseState copyWith({
    PurchaseStoreStatus? storeStatus,
    List<PremiumProduct>? products,
    PremiumWallet? wallet,
    bool? walletStale,
    Set<String>? pendingProductIds,
    bool? retryPending,
    String? message,
  }) => PurchaseState(
    storeStatus: storeStatus ?? this.storeStatus,
    products: products ?? this.products,
    wallet: wallet ?? this.wallet,
    walletStale: walletStale ?? this.walletStale,
    pendingProductIds: pendingProductIds ?? this.pendingProductIds,
    retryPending: retryPending ?? this.retryPending,
    message: message,
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
  final _completedTokens = <String>{};
  bool _started = false;
  PurchaseState _state = const PurchaseState();

  PurchaseState get state => _state;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = _gateway.updates.listen(_handleUpdate);
    await _gateway.recoverUnfinishedPurchases();
    if (_sessionProvider().isPermanent) {
      await _refreshWallet();
      await _retryDurablePurchases();
    }
    try {
      if (!await _gateway.isAvailable()) {
        _setState(
          _state.copyWith(storeStatus: PurchaseStoreStatus.unavailable),
        );
        return;
      }
      final products = await _gateway.loadProducts(PremiumProduct.ids);
      _setState(
        _state.copyWith(
          storeStatus: PurchaseStoreStatus.ready,
          products: List.unmodifiable(products),
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          storeStatus: PurchaseStoreStatus.error,
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> resume() async {
    await _gateway.recoverUnfinishedPurchases();
    if (_sessionProvider().isPermanent) {
      await _retryDurablePurchases();
    }
  }

  Future<PurchaseStartResult> purchase(PremiumProduct product) async {
    if (!_sessionProvider().isPermanent) {
      return PurchaseStartResult.accountRequired;
    }
    if (_state.storeStatus != PurchaseStoreStatus.ready) {
      return PurchaseStartResult.unavailable;
    }
    try {
      await _gateway.purchase(product);
      return PurchaseStartResult.started;
    } catch (error) {
      _setState(_state.copyWith(message: error.toString()));
      return PurchaseStartResult.error;
    }
  }

  void _handleUpdate(PurchaseUpdate update) {
    switch (update.status) {
      case PurchaseStatus.pending:
        _setPending(update.productId, true);
      case PurchaseStatus.canceled:
        _setPending(update.productId, false);
      case PurchaseStatus.error:
        _setPending(update.productId, false);
        _setState(_state.copyWith(message: update.errorMessage));
      case PurchaseStatus.purchased:
        _setPending(update.productId, false);
        unawaited(_processPurchased(update));
    }
  }

  Future<void> _retryDurablePurchases() async {
    final entries = await _retryStore.load();
    _setState(_state.copyWith(retryPending: entries.isNotEmpty));
    for (final entry in entries) {
      await _processPurchased(
        PurchaseUpdate.purchased(
          productId: entry.productId,
          purchaseToken: entry.purchaseToken,
        ),
        alreadyDurable: true,
      );
    }
  }

  Future<void> _processPurchased(
    PurchaseUpdate update, {
    bool alreadyDurable = false,
  }) async {
    final token = update.purchaseToken!;
    if (_completedTokens.contains(token) || !_processingTokens.add(token)) {
      return;
    }
    try {
      if (!alreadyDurable) {
        await _retryStore.put(
          PendingPurchase(productId: update.productId, purchaseToken: token),
        );
      }
      _setState(_state.copyWith(retryPending: true));
      await _repository
          .verifyPurchase(
            productId: update.productId,
            purchaseToken: token,
            packageName: _packageName,
          )
          .timeout(verificationTimeout);
      await _refreshWallet();
      await _gateway.complete(update);
      await _retryStore.remove(token);
      _completedTokens.add(token);
      final remaining = await _retryStore.load();
      _setState(_state.copyWith(retryPending: remaining.isNotEmpty));
    } catch (error) {
      _setState(_state.copyWith(retryPending: true, message: error.toString()));
    } finally {
      _processingTokens.remove(token);
    }
  }

  Future<void> _refreshWallet() async {
    try {
      final wallet = await _repository.fetchWallet();
      _setState(_state.copyWith(wallet: wallet, walletStale: false));
    } catch (_) {
      _setState(_state.copyWith(walletStale: true));
    }
  }

  void _setPending(String productId, bool pending) {
    final values = {..._state.pendingProductIds};
    pending ? values.add(productId) : values.remove(productId);
    _setState(_state.copyWith(pendingProductIds: Set.unmodifiable(values)));
  }

  void _setState(PurchaseState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
