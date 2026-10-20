part of 'studio_screens.dart';

class BriefScreen extends StatefulWidget {
  const BriefScreen({
    super.key,
    required this.repository,
    this.initialServiceTitle,
  });
  final StudioRepository repository;
  final String? initialServiceTitle;
  @override
  State<BriefScreen> createState() => _BriefScreenState();
}

class _BriefScreenState extends State<BriefScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _description = TextEditingController();
  final _selectedServices = <String>{};
  late Future<BriefOptions> _optionsFuture;
  BriefOptions? _options;
  String? _idempotencyKey;
  String? _submittedFingerprint;
  String? _error;
  bool _submitting = false;
  bool _allowPop = false;
  bool _confirmingDiscard = false;
  DateTime? _retryUntil;
  Timer? _retryTimer;
  int _retryInitialSeconds = 0;
  int _retryTicks = 0;

  bool get _hasDraft =>
      _name.text.isNotEmpty ||
      _contact.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _selectedServices.isNotEmpty;
  int get _retrySeconds => _retryUntil == null
      ? 0
      : min(
          max(0, _retryInitialSeconds - _retryTicks),
          max(
            0,
            (_retryUntil!.difference(DateTime.now()).inMilliseconds / 1000)
                .ceil(),
          ),
        );

  @override
  void initState() {
    super.initState();
    if (widget.initialServiceTitle != null) {
      _description.text = 'Интересует услуга «${widget.initialServiceTitle}».';
    }
    _optionsFuture = _loadOptions();
    for (final controller in [_name, _contact, _description]) {
      controller.addListener(_draftChanged);
    }
  }

  Future<BriefOptions> _loadOptions() async {
    final options = await widget.repository.briefOptions(_locale);
    _options = options;
    return options;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _name.dispose();
    _contact.dispose();
    _description.dispose();
    super.dispose();
  }

  void _draftChanged() => setState(() => _error = null);

  void _startCooldown(Duration duration) {
    _retryTimer?.cancel();
    _retryUntil = DateTime.now().add(duration);
    _retryInitialSeconds = (duration.inMilliseconds / 1000).ceil();
    _retryTicks = 0;
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _retryTicks = timer.tick;
        if (_retrySeconds == 0) timer.cancel();
      });
    });
  }

  Future<void> _confirmDiscard() async {
    if (_submitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дождитесь результата отправки заявки.')),
      );
      return;
    }
    if (_confirmingDiscard) return;
    _confirmingDiscard = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть заявку?'),
        content: const Text(
          'Введённые данные будут потеряны. Можно остаться и продолжить заполнение.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Продолжить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (discard == true && mounted) {
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  String _newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _submit() async {
    if (_submitting ||
        _retrySeconds > 0 ||
        _options == null ||
        !_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    final draft = BriefDraft(
      name: _name.text.trim(),
      contact: _contact.text.trim(),
      serviceIds: _selectedServices.toList()..sort(),
      description: _description.text.trim(),
      locale: _locale,
    );
    // Selection/focus changes are not request changes. Reuse the key after an
    // uncertain response unless the normalized payload itself has changed.
    final fingerprint = jsonEncode([
      draft.name,
      draft.contact,
      draft.serviceIds,
      draft.description,
      draft.locale.name,
    ]);
    if (_idempotencyKey == null || fingerprint != _submittedFingerprint) {
      _idempotencyKey = _newKey();
      _submittedFingerprint = fingerprint;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final receipt = await widget.repository.submitBrief(
        draft,
        idempotencyKey: _idempotencyKey!,
      );
      if (!mounted) return;
      _idempotencyKey = null;
      _submittedFingerprint = null;
      _allowPop = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BriefSuccessScreen(
            repository: widget.repository,
            receipt: receipt,
          ),
        ),
      );
    } on RepositoryException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          if (error.statusCode == 429 || error.code == 'RATE_LIMITED') {
            _startCooldown(error.retryAfter ?? const Duration(seconds: 60));
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Не удалось отправить заявку. Попробуйте ещё раз — введённые данные сохранены.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowPop || (!_hasDraft && !_submitting),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmDiscard();
    },
    child: DetailScaffold(
      repository: widget.repository,
      title: 'Обсудить проект',
      onBack: () {
        if (_hasDraft || _submitting) {
          _confirmDiscard();
        } else {
          Navigator.of(context).pop();
        }
      },
      body: Form(
        key: _formKey,
        child: PageBody(
          children: [
            const PageHeading(
              number: '05',
              title: 'Начнём\nс вашей идеи.',
              subtitle:
                  'Пара слов о задаче — и мы поймём, чем можем быть полезны.',
            ),
            if (widget.repository.isDemo)
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Panel(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: PipColors.amber,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Это макет формы. API не подключён, поэтому заявки пока не отправляются.',
                          style: TextStyle(
                            color: PipColors.muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            AsyncContent(
              future: _optionsFuture,
              onRetry: () => setState(() {
                _optionsFuture = _loadOptions();
              }),
              builder: (options) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('brief-name'),
                    controller: _name,
                    enabled: !_submitting,
                    maxLength: options.nameMax,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Как вас зовут *',
                      hintText: 'Ваше имя',
                    ),
                    validator: (value) {
                      final length = value?.trim().length ?? 0;
                      return length < options.nameMin ||
                              length > options.nameMax
                          ? 'Имя: от ${options.nameMin} до ${options.nameMax} символов'
                          : null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    key: const Key('brief-contact'),
                    controller: _contact,
                    enabled: !_submitting,
                    maxLength: options.contactMax,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Как с вами связаться *',
                      hintText: 'Email, телефон или Telegram',
                    ),
                    validator: (value) {
                      final contact = value?.trim() ?? '';
                      return contact.length < options.contactMin ||
                              contact.length > options.contactMax ||
                              !RegExp(
                                r'[\p{L}\d@]',
                                unicode: true,
                              ).hasMatch(contact)
                          ? 'Контакт: от ${options.contactMin} до ${options.contactMax} символов, с буквами или цифрами'
                          : null;
                    },
                  ),
                  const SectionHeading('Что вас интересует?'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(
                      'До ${options.servicesMax} направлений. Можно оставить на потом.',
                      style: const TextStyle(
                        color: PipColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in options.serviceOptions)
                        FilterChip(
                          label: Text(option),
                          selected: _selectedServices.contains(option),
                          onSelected:
                              _submitting ||
                                  (!_selectedServices.contains(option) &&
                                      _selectedServices.length >=
                                          options.servicesMax)
                              ? null
                              : (selected) => setState(() {
                                  _error = null;
                                  if (selected) {
                                    _selectedServices.add(option);
                                  } else {
                                    _selectedServices.remove(option);
                                  }
                                }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('brief-description'),
                    controller: _description,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: options.messageMax,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Расскажите о задаче',
                      hintText: 'Необязательно. Что хотите создать?',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        (value?.trim().length ?? 0) > options.messageMax
                        ? 'Не более ${options.messageMax} символов'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Semantics(
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF332322),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_retrySeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        'Повторная отправка через $_retrySeconds с',
                        key: const Key('brief-cooldown'),
                        style: const TextStyle(
                          color: PipColors.amber,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  FilledButton(
                    key: const Key('brief-submit'),
                    onPressed: _submitting || _retrySeconds > 0
                        ? null
                        : _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_submitting) ...[
                          const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            _submitting ? 'Отправляем…' : 'Отправить заявку',
                          ),
                        ),
                        if (!_submitting) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.north_east_rounded, size: 19),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '* Обязательные поля',
                    style: TextStyle(color: PipColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class BriefSuccessScreen extends StatelessWidget {
  const BriefSuccessScreen({
    super.key,
    required this.repository,
    required this.receipt,
  });
  final StudioRepository repository;
  final BriefReceipt receipt;
  @override
  Widget build(BuildContext context) => DetailScaffold(
    repository: repository,
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
        const SizedBox(height: 18),
        Text(
          'Номер заявки: ${receipt.id}',
          style: const TextStyle(color: PipColors.muted, fontSize: 12),
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
