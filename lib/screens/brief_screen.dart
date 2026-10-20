import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models.dart';
import '../widgets/common_widgets.dart';

class BriefScreen extends StatefulWidget {
  const BriefScreen({super.key, required this.data, this.initialServiceTitle});
  final DemoData data;
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
  String? _error;
  bool _allowPop = false;
  bool _confirmingDiscard = false;

  bool get _hasDraft =>
      _name.text.isNotEmpty ||
      _contact.text.isNotEmpty ||
      _description.text.isNotEmpty ||
      _selectedServices.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Из услуги переносим только описание: допустимые названия направлений
    // отдельно прочитаем из локальных настроек формы.
    if (widget.initialServiceTitle != null) {
      _description.text = 'Интересует услуга «${widget.initialServiceTitle}».';
    }
    _optionsFuture = _loadOptions();
    for (final controller in [_name, _contact, _description]) {
      controller.addListener(_draftChanged);
    }
  }

  Future<BriefOptions> _loadOptions() async {
    // Берём варианты и ограничения полей из локальных данных макета.
    final options = await widget.data.getBriefOptions(contentLocale);
    _options = options;
    return options;
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _description.dispose();
    super.dispose();
  }

  void _draftChanged() => setState(() => _error = null);

  Future<void> _confirmDiscard() async {
    // Не теряем введённые данные при случайном нажатии «Назад».
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

  void _submit() {
    if (_options == null || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // TODO: здесь позже будет отправка заявки через API.
    setState(() {
      _error =
          'API ещё не подключён. Заявка не отправлена; введённые данные сохранены на этом экране.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _allowPop || !_hasDraft,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _confirmDiscard();
    },
    child: DetailScaffold(
      data: widget.data,
      title: 'Обсудить проект',
      onBack: () {
        if (_hasDraft) {
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
            if (widget.data.isDemo)
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
                  FilledButton(
                    key: const Key('brief-submit'),
                    onPressed: _submit,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(child: Text('Отправить заявку')),
                        SizedBox(width: 12),
                        Icon(Icons.north_east_rounded, size: 19),
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
