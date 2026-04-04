import 'package:flutter/foundation.dart';

class AppEnv {
  // Python import service endpoint for development.
  // 可通过 --dart-define=API_BASE_URL=... 覆盖默认值。
  static String get apiBaseUrl {
    const String override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return override;
    }

    // Android 模拟器访问宿主机 localhost 需要使用 10.0.2.2。
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
