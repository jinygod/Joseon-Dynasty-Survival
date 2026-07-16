import 'package:flutter/material.dart';

import 'accessible_status_badge.dart';
import 'credits_ledger.dart';

class CreditsLicensesScreen extends StatefulWidget {
  const CreditsLicensesScreen({
    this.loader = CreditsLedger.loadBundled,
    super.key,
  });

  final CreditsLedgerLoader loader;

  @override
  State<CreditsLicensesScreen> createState() => _CreditsLicensesScreenState();
}

class _CreditsLicensesScreenState extends State<CreditsLicensesScreen> {
  late Future<CreditsLedger> _ledger;

  @override
  void initState() {
    super.initState();
    _ledger = widget.loader();
  }

  @override
  void didUpdateWidget(CreditsLicensesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) _ledger = widget.loader();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('\uD06C\uB808\uB527 \uBC0F \uB77C\uC774\uC120\uC2A4'),
    ),
    body: SafeArea(
      child: FutureBuilder<CreditsLedger>(
        future: _ledger,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '\uD06C\uB808\uB527 \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 '
                  '\uBABB\uD588\uC2B5\uB2C8\uB2E4.',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ledger = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Title(
                Icons.image_outlined,
                '\uBC88\uB4E4 \uC774\uBBF8\uC9C0 \uC790\uC0B0',
              ),
              ...ledger.assets.map(_CreditCard.new),
              const SizedBox(height: 20),
              const _Title(
                Icons.music_note_outlined,
                '\uBC88\uB4E4 \uC74C\uC6D0',
              ),
              ...ledger.audio.map(_CreditCard.new),
              if (ledger.assets.isEmpty && ledger.audio.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      '\uD45C\uC2DC\uD560 \uD06C\uB808\uB527 \uC815\uBCF4\uAC00 '
                      '\uC5C6\uC2B5\uB2C8\uB2E4.',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _CreditCard extends StatelessWidget {
  const _CreditCard(this.entry);

  final CreditEntry entry;

  @override
  Widget build(BuildContext context) {
    final approved = entry.status == 'approved';
    final temporary = entry.status == 'temporary';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleStatusBadge(
              icon: approved
                  ? Icons.verified_outlined
                  : temporary
                  ? Icons.schedule_outlined
                  : Icons.help_outline,
              label: approved
                  ? '\uC2B9\uC778\uB428'
                  : temporary
                  ? '\uC784\uC2DC'
                  : entry.status,
              semanticsLabel: '\uC790\uC0B0 \uC0C1\uD0DC ${entry.status}',
            ),
            const SizedBox(height: 12),
            Text(entry.creator, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(entry.runtimePath),
            Text(entry.license),
            Text(entry.sourceUrl),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    ),
  );
}
