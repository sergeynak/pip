import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import 'brief_screen.dart';

// Открываем форму из любой кнопки и передаём ей текущий источник данных.
void openBrief(BuildContext context, DemoData data, {String? serviceTitle}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BriefScreen(data: data, initialServiceTitle: serviceTitle),
    ),
  );
}
