import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../widgets/common_widgets.dart';

// TODO: открывать этот экран только после подключения отправки заявки.
class BriefSuccessScreen extends StatelessWidget {
  const BriefSuccessScreen({super.key, required this.data});
  final DemoData data;
  @override
  Widget build(BuildContext context) => DetailScaffold(
    data: data,
    title: 'Заявка',
    body: PageBody(
      children: [
        const SizedBox(height: 45),
        const Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: PipColors.accent,
            child: Icon(Icons.check_rounded, size: 36, color: Colors.white),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Заявка\nотправлена.',
          style: TextStyle(
            fontSize: 38,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Спасибо за вашу идею. Студия получила заявку и сможет связаться с вами по указанному контакту.',
          style: TextStyle(color: PipColors.muted, height: 1.7, fontSize: 16),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Вернуться в приложение'),
        ),
      ],
    ),
  );
}
