import 'package:flutter/foundation.dart';

abstract final class SafeAssetLoader {
  static Future<T?> load<T>({
    required Future<T> Function() load,
    required String library,
    required String assetKey,
    bool reportErrors = !kReleaseMode,
    void Function(FlutterErrorDetails) reportError = FlutterError.reportError,
  }) async {
    try {
      return await load();
    } catch (error, stackTrace) {
      if (reportErrors) {
        reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: library,
            context: ErrorDescription('loading $assetKey'),
          ),
        );
      }
      return null;
    }
  }
}
