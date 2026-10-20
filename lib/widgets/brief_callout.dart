import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../screens/navigation.dart';
import 'common_widgets.dart';

class BriefCallout extends StatelessWidget {
  const BriefCallout({super.key, required this.data});
  final DemoData data;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('СЛЕДУЮЩИЙ ШАГ', color: Color(0xFFB49DEB)),
        const SizedBox(height: 14),
        const Text(
          'Есть идея?\nДавайте обсудим.',
          style: TextStyle(
            fontSize: 27,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => openBrief(context, data),
            child: const Text('Оставить заявку'),
          ),
        ),
      ],
    ),
  );
}
