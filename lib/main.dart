import 'package:flutter/material.dart';

import 'api/api_service.dart';
import 'api/demo_api_service.dart';
import 'app.dart';

// С этой функции начинается работа приложения.
void main() {
  // Обычно используем API сайта. Примеры включаются параметром при запуске:
  // flutter run --dart-define=USE_DEMO_DATA=true
  const useDemoData = bool.fromEnvironment('USE_DEMO_DATA');

  final ApiService api;
  if (useDemoData) {
    api = DemoApiService();
  } else {
    api = ApiService();
  }

  // Передаём работу с данными приложению и запускаем интерфейс.
  runApp(PipApp(api: api));
}
