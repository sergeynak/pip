import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';

import 'api/api_service.dart';
import 'screens/blog_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/home_screen.dart';
import 'screens/navigation.dart';
import 'screens/portfolio_screen.dart';
import 'screens/services_screen.dart';
import 'widgets/common_widgets.dart';

class PipApp extends StatefulWidget {
  const PipApp({super.key, required this.api});
  final ApiService api;

  @override
  State<PipApp> createState() => _PipAppState();
}

class _PipAppState extends State<PipApp> {
  @override
  void dispose() {
    // Освобождаем HTTP-клиент, когда приложение больше не используется.
    widget.api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = ColorScheme.dark(
      primary: PipColors.accent,
      onPrimary: Colors.white,
      secondary: PipColors.amber,
      onSecondary: PipColors.background,
      surface: PipColors.panel,
      onSurface: PipColors.text,
      onSurfaceVariant: PipColors.muted,
      outline: PipColors.border,
      error: Color(0xFFFFB4AB),
    );
    return MaterialApp(
      title: 'pip',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: PipColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: PipColors.background,
          foregroundColor: PipColors.text,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: PipColors.panel,
          indicatorColor: PipColors.accent.withValues(alpha: .25),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? PipColors.text
                  : PipColors.muted,
              fontSize: 10,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: PipColors.panel,
          contentPadding: const EdgeInsets.all(18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: PipColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: PipColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: PipColors.accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: PipColors.muted),
          hintStyle: const TextStyle(color: PipColors.muted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PipColors.text,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
            side: const BorderSide(color: PipColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: PipColors.border,
          thickness: 1,
        ),
      ),
      home: StudioShell(api: widget.api),
    );
  }
}

class StudioShell extends StatefulWidget {
  const StudioShell({super.key, required this.api});
  final ApiService api;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int _index = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Создаём вкладки один раз: при переключении поиск и прокрутка сохранятся.
    _pages = [
      HomeScreen(api: widget.api, onTab: (i) => setState(() => _index = i)),
      ServicesScreen(api: widget.api),
      PortfolioScreen(api: widget.api),
      BlogScreen(api: widget.api),
      ContactsScreen(api: widget.api),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 22,
      toolbarHeight: 66,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'pip',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w900,
                letterSpacing: -3,
              ),
            ),
            SizedBox(width: 14),
            Text(
              'DIGITAL STUDIO',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: PipColors.muted,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton.filledTonal(
          onPressed: () => openBrief(context, widget.api),
          tooltip: 'Обсудить проект',
          icon: const Icon(Icons.north_east_rounded, size: 21),
        ),
        const SizedBox(width: 15),
      ],
      bottom: widget.api.isDemo
          ? const PreferredSize(
              preferredSize: Size.fromHeight(35),
              child: DemoNotice(),
            )
          : null,
    ),
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: NavigationBar(
      height: 76,
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Главная',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Услуги',
        ),
        NavigationDestination(
          icon: Icon(Icons.layers_outlined),
          selectedIcon: Icon(Icons.layers_rounded),
          label: 'Портфолио',
        ),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          selectedIcon: Icon(Icons.article_rounded),
          label: 'Блог',
        ),
        NavigationDestination(
          icon: Icon(Icons.alternate_email_rounded),
          label: 'Контакты',
        ),
      ],
    ),
  );
}
