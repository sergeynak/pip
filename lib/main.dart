import 'package:flutter/material.dart';

import 'api/demo_api_service.dart';
import 'app.dart';

// С этой функции начинается работа приложения.
void main() {
  // Пока показываем вёрстку с локальными примерами. Запросов к сайту нет.
  // Позже здесь можно подключить ApiService, когда его методы будут готовы.
  final api = DemoApiService();
  runApp(PipApp(api: api));
}
