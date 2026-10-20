import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../screens/service_screen.dart';
import 'common_widgets.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.index,
    required this.data,
    this.compact = false,
  });
  final StudioService service;
  final int index;
  final DemoData data;
  final bool compact;
  @override
  Widget build(BuildContext context) => Panel(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceScreen(service: service, data: data),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: const TextStyle(
                color: PipColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                service.title.resolve(contentLocale),
                style: TextStyle(
                  fontSize: compact ? 17 : 21,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.north_east_rounded,
              size: 20,
              color: PipColors.muted,
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: 18),
          Text(
            service.description.resolve(contentLocale),
            style: const TextStyle(
              color: PipColors.muted,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            service.startingPrice ?? 'Стоимость появится позже',
            style: TextStyle(
              color: service.startingPrice == null
                  ? PipColors.muted
                  : PipColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    ),
  );
}
