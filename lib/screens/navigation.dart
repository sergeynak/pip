import 'package:flutter/material.dart';

import '../api/api_service.dart';
import 'brief_screen.dart';

// Открываем форму из любой кнопки и передаём ей текущий источник данных.
void openBrief(BuildContext context, ApiService api, {String? serviceTitle}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BriefScreen(api: api, initialServiceTitle: serviceTitle),
    ),
  );
}
