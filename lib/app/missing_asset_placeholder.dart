import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MissingAssetPlaceholder extends StatelessWidget {
  const MissingAssetPlaceholder({required this.assetKey, super.key});

  final String assetKey;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff312b25),
    child: Center(
      child: kDebugMode
          ? Text(
              'ASSET MISSING\n$assetKey',
              key: Key('missing-asset-$assetKey'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xffffd66b), fontSize: 12),
            )
          : const SizedBox.shrink(),
    ),
  );
}
