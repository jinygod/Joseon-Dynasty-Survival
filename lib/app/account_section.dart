import 'dart:async';

import 'package:flutter/material.dart';

import '../backend/account/account_controller.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({
    required this.controller,
    this.syncLabel,
    this.onSyncNow,
    this.syncListenable,
    super.key,
  });

  final AccountController controller;
  final String? syncLabel;
  final Future<void> Function()? onSyncNow;
  final Listenable? syncListenable;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        controller,
        if (syncListenable != null) syncListenable!,
      ]),
      builder: (context, _) {
        final session = controller.session;
        final transitionBlocked =
            controller.availability == AccountAvailability.blocked;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  session.isPermanent ? session.email! : '게스트 · 이 기기에만 저장',
                  key: const Key('account-summary'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (syncLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(syncLabel!),
                ],
                if (controller.errorMessage case final message?) ...[
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 8),
                if (transitionBlocked) ...[
                  FilledButton.icon(
                    key: const Key('retry-account-cleanup'),
                    onPressed: controller.busy
                        ? null
                        : () => unawaited(controller.retryBlockedTransition()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry account cleanup'),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: session.isPermanent
                      ? [
                          if (onSyncNow != null)
                            OutlinedButton.icon(
                              key: const Key('sync-now'),
                              onPressed: controller.busy || transitionBlocked
                                  ? null
                                  : () => unawaited(onSyncNow!()),
                              icon: const Icon(Icons.sync),
                              label: const Text('지금 동기화'),
                            ),
                          TextButton(
                            key: const Key('account-sign-out'),
                            onPressed: controller.busy || transitionBlocked
                                ? null
                                : () => unawaited(controller.signOut()),
                            child: const Text('로그아웃'),
                          ),
                          TextButton(
                            key: const Key('delete-account'),
                            onPressed: controller.busy || transitionBlocked
                                ? null
                                : () => unawaited(_confirmDelete(context)),
                            child: const Text('계정 삭제'),
                          ),
                        ]
                      : [
                          FilledButton.icon(
                            key: const Key('connect-google'),
                            onPressed:
                                controller.busy ||
                                    transitionBlocked ||
                                    controller.availability ==
                                        AccountAvailability.disabled
                                ? null
                                : () => unawaited(controller.connectGoogle()),
                            icon: const Icon(Icons.account_circle_outlined),
                            label: const Text('Google 계정 연결'),
                          ),
                        ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: const Text('클라우드 계정 데이터는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            key: const Key('delete-account-cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('delete-account-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteAccount();
  }
}
