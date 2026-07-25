import 'package:flutter/material.dart';

import '../backend/economy/premium_wallet.dart';

class PremiumWalletBadge extends StatelessWidget {
  const PremiumWalletBadge({
    super.key,
    required this.wallet,
    required this.stale,
  });

  final PremiumWallet? wallet;
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final unavailable = stale || wallet == null;
    return Semantics(
      label: unavailable
          ? '\uae08\uc625 \uc794\uc561\uc744 \ud655\uc778\ud560 \uc218 \uc5c6\uc74c'
          : '\uae08\uc625 ${wallet!.balance}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff2f2434),
          border: Border.all(color: const Color(0xffd6af57)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Text(
            unavailable
                ? '\uae08\uc625 \u2014'
                : '\uae08\uc625 ${wallet!.balance}',
          ),
        ),
      ),
    );
  }
}
