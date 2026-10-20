part of 'studio_screens.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key, required this.repository});
  final StudioRepository repository;
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late Future<StudioContact> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.contacts(_locale);
  }

  @override
  Widget build(BuildContext context) => PageBody(
    onRefresh: () async {
      setState(() {
        _future = widget.repository.contacts(_locale);
      });
      try {
        await _future;
      } catch (_) {
        /* Rendered by AsyncContent. */
      }
    },
    children: [
      const PageHeading(
        number: '04',
        title: 'Давайте\nзнакомиться.',
        subtitle: 'Расскажите о своей идее. Всё начинается с разговора.',
      ),
      AsyncContent(
        future: _future,
        onRetry: () => setState(() {
          _future = widget.repository.contacts(_locale);
        }),
        builder: (contacts) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ContactCard(
              icon: Icons.send_outlined,
              title: 'Telegram',
              value: contacts.telegram?.toString(),
              onTap: contacts.telegram == null
                  ? null
                  : () => openExternal(context, contacts.telegram!),
            ),
            const SizedBox(height: 13),
            _ContactCard(
              icon: Icons.mail_outline_rounded,
              title: 'Почта',
              value: contacts.email,
              onTap: contacts.email == null
                  ? null
                  : () => openExternal(
                      context,
                      Uri(scheme: 'mailto', path: contacts.email!),
                      allowEmail: true,
                    ),
            ),
            if (contacts.websiteUrl != null) ...[
              const SizedBox(height: 13),
              _ContactCard(
                icon: Icons.language_rounded,
                title: 'Сайт',
                value: contacts.websiteUrl.toString(),
                onTap: () => openExternal(context, contacts.websiteUrl!),
              ),
            ],
            const SectionHeading('О студии'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'pip',
                    style: TextStyle(
                      fontSize: 46,
                      letterSpacing: -4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    contacts.about?.resolve(_locale) ??
                        'Информация о студии пока не опубликована.',
                    style: const TextStyle(color: PipColors.muted, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 30),
      _BriefCallout(repository: widget.repository),
    ],
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Panel(
    onTap: onTap,
    child: Row(
      children: [
        Icon(icon, color: PipColors.accent, size: 24),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value ?? 'Контакт пока не опубликован',
                style: const TextStyle(
                  color: PipColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              if (value != null)
                const Text(
                  'Нажмите, чтобы открыть',
                  style: TextStyle(
                    color: PipColors.muted,
                    fontSize: 11,
                    height: 1.8,
                  ),
                ),
            ],
          ),
        ),
        if (value != null)
          const Icon(
            Icons.open_in_new_rounded,
            color: PipColors.muted,
            size: 18,
          ),
      ],
    ),
  );
}
