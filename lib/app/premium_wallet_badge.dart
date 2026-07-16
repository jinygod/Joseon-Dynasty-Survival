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
      label: unavailable ? '금옥 잔액을 확인할 수 없음' : '금옥 ${wallet!.balance}',
      excludeSemantics: true,
      child: Chip(label: Text(unavailable ? '금옥 —' : '금옥 ${wallet!.balance}')),
    );
  }
}
