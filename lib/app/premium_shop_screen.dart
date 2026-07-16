import 'package:flutter/material.dart';

import '../backend/economy/purchase_controller.dart';
import '../backend/economy/purchase_gateway.dart';
import 'premium_wallet_badge.dart';

class PremiumShopScreen extends StatelessWidget {
  const PremiumShopScreen({
    super.key,
    required this.controller,
    this.onAccountLinkRequired,
  });

  final PurchaseController controller;
  final VoidCallback? onAccountLinkRequired;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('금옥 상점')),
    body: AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: PremiumWalletBadge(
                wallet: state.wallet,
                stale: state.walletStale,
              ),
            ),
            if (state.pendingProductIds.isNotEmpty) const Text('결제 승인 대기 중'),
            if (state.retryPending) const Text('구매 확인 다시 시도'),
            for (final product in state.products) _productTile(product),
          ],
        );
      },
    ),
  );

  Widget _productTile(PremiumProduct product) => ListTile(
    title: Text(product.title),
    subtitle: Text(product.description),
    trailing: FilledButton(
      key: Key('premium-buy-${product.id}'),
      onPressed: () async {
        final result = await controller.purchase(product);
        if (result == PurchaseStartResult.accountRequired) {
          onAccountLinkRequired?.call();
        }
      },
      child: Text(product.price),
    ),
  );
}
