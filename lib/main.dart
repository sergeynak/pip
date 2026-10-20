import 'package:flutter/material.dart';

import 'app.dart';
import 'data/demo_data.dart';

// С этой функции начинается работа приложения.
void main() {
  // Показываем вёрстку с локальными примерами. Подключение API ещё не сделано.
  runApp(PipApp(data: DemoData()));
}
