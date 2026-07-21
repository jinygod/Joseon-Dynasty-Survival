import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class MobilePreviewPolicy {
  static const requested = bool.fromEnvironment(
    'MOBILE_PREVIEW',
    defaultValue: true,
  );

  static bool shouldEnable({
    required bool isWeb,
    required bool isDebug,
    required bool requested,
  }) => isWeb && isDebug && requested;

  static bool get enabled =>
      shouldEnable(isWeb: kIsWeb, isDebug: kDebugMode, requested: requested);
}

class MobilePreviewFrame extends StatelessWidget {
  const MobilePreviewFrame({
    required this.child,
    required this.enabled,
    super.key,
  });

  static const referenceSize = Size(390, 844);
  static const safeAreaPadding = EdgeInsets.only(top: 24, bottom: 16);
  static const backgroundKey = Key('mobile-preview-background');
  static const frameKey = Key('mobile-preview-frame');

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final media = MediaQuery.of(context);
    return ColoredBox(
      key: backgroundKey,
      color: const Color(0xff090d12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox.fromSize(
            key: frameKey,
            size: referenceSize,
            child: MediaQuery(
              data: media.copyWith(
                size: referenceSize,
                padding: safeAreaPadding,
                viewPadding: safeAreaPadding,
                viewInsets: EdgeInsets.zero,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
