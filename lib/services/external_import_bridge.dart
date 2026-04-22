import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges Android intents (VIEW / SEND) so other apps (e.g. QQ) can open .msb.
class ExternalImportBridge {
  ExternalImportBridge._();

  static const MethodChannel _import =
      MethodChannel('com.meme.meme_soundboard/import');
  static const MethodChannel _importPush =
      MethodChannel('com.meme.meme_soundboard/import_push');

  /// Android: copy content URI to cache and return a real file path, then clear pending.
  static Future<String?> consumePendingAndroidPath() async {
    if (!Platform.isAndroid) return null;
    try {
      final path = await _import.invokeMethod<String>('consumePendingImport');
      return path;
    } catch (e, st) {
      debugPrint('ExternalImportBridge.consumePendingAndroidPath: $e\n$st');
      return null;
    }
  }

  /// Register handler for paths pushed while app is already running (onNewIntent).
  static void listenAndroidPush(void Function(String path) onPath) {
    if (!Platform.isAndroid) return;
    _importPush.setMethodCallHandler((call) async {
      if (call.method == 'pendingImport') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          onPath(path);
        }
      }
    });
  }

  static void clearAndroidPush() {
    if (!Platform.isAndroid) return;
    _importPush.setMethodCallHandler(null);
  }
}
