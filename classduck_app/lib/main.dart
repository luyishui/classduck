import 'package:flutter/material.dart';

import 'app/app.dart';

import 'shared/notification_service.dart';

void main() {
  // 初始化本地通知服务
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.initialize();
  runApp(const ClassDuckApp());
}
