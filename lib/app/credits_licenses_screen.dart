import 'package:flutter/material.dart';

import 'credits_ledger.dart';

class CreditsLicensesScreen extends StatelessWidget {
  const CreditsLicensesScreen({this.ledger = CreditsLedger.bundled, super.key});

  final CreditsLedger ledger;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('\uD06C\uB808\uB527 \uBC0F \uB77C\uC774\uC120\uC2A4'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Title(
            Icons.image_outlined,
            '\uBC88\uB4E4 \uC774\uBBF8\uC9C0 \uC790\uC0B0',
          ),
          ...ledger.assets.map(_card),
          const SizedBox(height: 20),
          const _Title(Icons.music_note_outlined, '\uBC88\uB4E4 \uC74C\uC6D0'),
          ...ledger.audio.map(_card),
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
      ),
    ),
  );

  Widget _card(CreditEntry entry) => Card(
    child: ListTile(
      leading: const Icon(Icons.verified_outlined),
      title: Text(entry.creator),
      subtitle: Text(
        '${entry.runtimePath}\n${entry.license}\n${entry.sourceUrl}',
      ),
      isThreeLine: true,
    ),
  );
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
