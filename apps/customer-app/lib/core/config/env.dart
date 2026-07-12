import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend API base URL. Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://api.trimly.app/api/v1
/// Falls back to sensible per-platform localhost defaults for local dev.
class Env {
  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return 'http://localhost:4000/api/v1';
    if (Platform.isAndroid) return 'http://10.0.2.2:4000/api/v1';
    return 'http://localhost:4000/api/v1';
  }

  /// Socket.IO connects to the bare server origin — Nest's global `/api/v1`
  /// prefix only applies to REST controllers, not the WebSocket gateway.
  static String get socketBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
