import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app/app.dart';

void main() {
  // 统一数据库初始化：
  // - Web 端暂不启用 sqflite_ffi_web（缺少 worker 资源会导致初始化失败）
  // - 桌面调试使用 sqflite_common_ffi
  // - Android/iOS 保持 sqflite 默认实现
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ClassDuckApp());
}
