part of 'studio_screens.dart';

class _BriefCallout extends StatelessWidget {
  const _BriefCallout({required this.repository});
  final StudioRepository repository;
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
            onPressed: () => openBrief(context, repository),
            child: const Text('Оставить заявку'),
          ),
        ),
      ],
    ),
  );
}
