import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/studio_repository.dart';

abstract final class PipColors {
  static const background = Color(0xFF111118);
  static const panel = Color(0xFF17171F);
  static const accent = Color(0xFF7853D9);
  static const text = Color(0xFFEFECF5);
  static const muted = Color(0xFFA19DB1);
  static const amber = Color(0xFFF39900);
  static const border = Color(0xFF2C2937);
}

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 11),
    child: const Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      children: [
        Icon(Icons.circle, size: 6, color: PipColors.amber),
        Text(
          'Макет · API не подключён',
          style: TextStyle(color: PipColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: onRefresh == null
          ? _list()
          : RefreshIndicator(onRefresh: onRefresh!, child: _list()),
    ),
  );

  Widget _list() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
    children: children,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = PipColors.muted});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.6,
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow('$number / PIP STUDIO'),
      const SizedBox(height: 14),
      Text(
        title,
        style: const TextStyle(
          fontSize: 34,
          height: 1.12,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 13),
      Text(
        subtitle,
        style: const TextStyle(
          color: PipColors.muted,
          height: 1.6,
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 28),
    ],
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
    this.title, {
    super.key,
    this.onAll,
    this.action = 'Все',
  });
  final String title;
  final VoidCallback? onAll;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
        ),
        if (onAll != null)
          TextButton(
            onPressed: onAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 16),
              ],
            ),
          ),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: PipColors.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: PipColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class AsyncContent<T> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
  });
  final Future<T> future;
  final Widget Function(T) builder;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final missing = error is RepositoryException && error.statusCode == 404;
        return Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                missing ? 'Материал недоступен' : 'Не удалось загрузить данные',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                missing
                    ? 'Возможно, материал удалён или ещё не опубликован. Вернитесь к списку и обновите его.'
                    : error is RepositoryException
                    ? error.message
                    : 'Проверьте соединение и попробуйте ещё раз.',
                style: TextStyle(color: PipColors.muted),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ],
          ),
        );
      }
      return builder(snapshot.data as T);
    },
  );
}

class EmptyContent extends StatelessWidget {
  const EmptyContent(this.title, this.description, {super.key});
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.inbox_outlined, color: PipColors.muted, size: 30),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: PipColors.muted, height: 1.5),
        ),
      ],
    ),
  );
}

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.repository,
    required this.title,
    required this.body,
    this.onBack,
  });
  final StudioRepository repository;
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: onBack == null ? null : BackButton(onPressed: onBack),
      title: Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      bottom: repository.isDemo
          ? const PreferredSize(
              preferredSize: Size.fromHeight(35),
              child: DemoNotice(),
            )
          : null,
    ),
    body: SafeArea(top: false, child: body),
  );
}

class ExampleTag extends StatelessWidget {
  const ExampleTag({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(30),
    ),
    child: const Text(
      'ПРИМЕР',
      style: TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.white70),
    ),
  );
}

class ProjectArtwork extends StatelessWidget {
  const ProjectArtwork({
    super.key,
    required this.variant,
    this.imageUrl,
    this.demo = false,
    this.fit = BoxFit.cover,
  });
  final int variant;
  final Uri? imageUrl;
  final bool demo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl.toString(),
        fit: fit,
        width: double.infinity,
        errorBuilder: (context, error, stack) => const Center(
          child: Icon(Icons.broken_image_outlined, color: PipColors.muted),
        ),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!demo) {
      return const ColoredBox(
        color: PipColors.panel,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: PipColors.muted, size: 34),
              SizedBox(height: 9),
              Text(
                'Без обложки',
                style: TextStyle(color: PipColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    final violet = variant % 3 == 0;
    final orange = variant % 3 == 1;
    final accent = violet
        ? const Color(0xFFB398FF)
        : orange
        ? const Color(0xFFF4AD5B)
        : const Color(0xFFA4BAAA);
    return MediaQuery.withNoTextScaling(
      child: Semantics(
        label: 'Демонстрационная иллюстрация проекта',
        image: true,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: violet
                  ? [const Color(0xFF3A285B), const Color(0xFF20182E)]
                  : orange
                  ? [const Color(0xFF523D29), const Color(0xFF2C241F)]
                  : [const Color(0xFF33433D), const Color(0xFF1D2A25)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -40,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: .13),
                        width: 35,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.rotate(
                    angle: violet ? -.08 : .07,
                    child: Container(
                      width: constraints.maxWidth * .67,
                      height: constraints.maxHeight * .67,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF17171F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .3),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: PipColors.border,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 25,
                                height: 3,
                                color: PipColors.border,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            violet
                                ? 'Make\nit simple.'
                                : orange
                                ? 'Form.\nFeeling.'
                                : 'Less,\nbut better.',
                            style: TextStyle(
                              fontSize: 24,
                              height: .95,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: -1,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(width: 40, height: 4, color: accent),
                              const SizedBox(width: 6),
                              Container(
                                width: 20,
                                height: 4,
                                color: PipColors.border,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> openExternal(
  BuildContext context,
  Uri uri, {
  bool allowEmail = false,
}) async {
  final web =
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
  final email =
      allowEmail &&
      uri.scheme == 'mailto' &&
      uri.path.isNotEmpty &&
      !uri.path.contains(RegExp(r'[\r\n]'));
  if (!web && !email) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Эту ссылку нельзя открыть.')));
    return;
  }
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // A browser or mail application may be unavailable on this device.
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Не удалось открыть ссылку на этом устройстве.'),
        action: SnackBarAction(
          label: 'Скопировать',
          onPressed: () => copyValue(context, uri.toString(), 'Ссылка'),
        ),
      ),
    );
  }
}

class GalleryImage extends StatelessWidget {
  const GalleryImage({super.key, required this.image});
  final ProjectImage image;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Panel(
          padding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _ImageViewer(image: image)),
          ),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProjectArtwork(
                  variant: 0,
                  imageUrl: image.thumbnailUrl ?? image.url,
                  fit: BoxFit.contain,
                ),
                const Positioned(
                  right: 10,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xCC111118),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.zoom_in_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (image.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              image.caption,
              style: const TextStyle(
                color: PipColors.muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
      ],
    ),
  );
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.image});
  final ProjectImage image;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Галерея'),
      actions: [
        IconButton(
          tooltip: 'Открыть оригинал',
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: () => openExternal(context, image.url),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Раздвиньте пальцы для увеличения. Перемещайте изображение.',
              style: TextStyle(color: PipColors.muted, fontSize: 12),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, size) => InteractiveViewer(
                constrained: false,
                minScale: .2,
                maxScale: 5,
                boundaryMargin: const EdgeInsets.all(80),
                child: Image.network(
                  image.url.toString(),
                  width: size.maxWidth,
                  fit: BoxFit.contain,
                  semanticLabel: image.caption.isEmpty
                      ? 'Изображение проекта'
                      : image.caption,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: size.maxWidth,
                    height: 200,
                    child: const Center(
                      child: Text('Не удалось загрузить изображение'),
                    ),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : SizedBox(
                          width: size.maxWidth,
                          height: 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> copyValue(BuildContext context, String value, String label) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label скопировано')));
  }
}
