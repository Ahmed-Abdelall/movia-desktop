import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/localization/strings.dart';
import 'features/events/application/event_providers.dart';
import 'features/events/presentation/screens.dart';

final _router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
        GoRoute(path: '/archive', builder: (_, _) => const ArchiveScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(path: '/event/:id', builder: (_, state) => EventDetailsScreen(id: state.pathParameters['id']!)),
      ],
    ),
  ],
);

class MoviaApp extends ConsumerWidget {
  const MoviaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const SettingsState();
    final themeMode = switch (settings.theme) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF312E81), brightness: Brightness.light);
    final darkScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF818CF8), brightness: Brightness.dark);
    ThemeData makeTheme(ColorScheme scheme) => ThemeData(
      useMaterial3: true, colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant))),
    );
    final locale = switch (settings.language) {
      'en' => const Locale('en'), 'ar' => const Locale('ar'), _ => null,
    };
    return MaterialApp.router(
      title: 'Movia', debugShowCheckedModeBanner: false, routerConfig: _router,
      theme: makeTheme(lightScheme), darkTheme: makeTheme(darkScheme), themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('dashboard', Icons.dashboard_outlined, '/dashboard'),
      ('calendar', Icons.calendar_month_outlined, '/calendar'),
      ('archive', Icons.inventory_2_outlined, '/archive'),
      ('settings', Icons.settings_outlined, '/settings'),
    ];
    final selected = items.indexWhere((e) => location.startsWith(e.$3));
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): const _NavigateIntent('/dashboard'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): const _NavigateIntent('/calendar'),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): const _NavigateIntent('/archive'),
        const SingleActivator(LogicalKeyboardKey.comma, control: true): const _NavigateIntent('/settings'),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): const _AddIntent(),
      },
      child: Actions(
        actions: {
          _NavigateIntent: CallbackAction<_NavigateIntent>(onInvoke: (i) => context.go(i.path)),
          _AddIntent: CallbackAction<_AddIntent>(onInvoke: (_) => showEventEditor(context)),
        },
        child: Focus(autofocus: true, child: Scaffold(
          body: Row(children: [
            Container(
              width: 236, decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: BorderDirectional(end: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(padding: const EdgeInsets.fromLTRB(24, 28, 24, 30), child: Row(children: [
                  Icon(Icons.event_available, color: Theme.of(context).colorScheme.primary, size: 30),
                  const SizedBox(width: 12), const Text('Movia', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                ])),
                ...List.generate(items.length, (i) {
                  final item = items[i];
                  return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), child: ListTile(
                    selected: selected == i, leading: Icon(item.$2), title: Text(s(context).t(item.$1)),
                    trailing: Text(i < 3 ? 'Ctrl+${i + 1}' : 'Ctrl+,', style: Theme.of(context).textTheme.labelSmall),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), onTap: () => context.go(item.$3)));
                }),
                const Spacer(),
                Padding(padding: const EdgeInsets.all(20), child: Text('Movia 1.0.0\nWindows', style: Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
            Expanded(child: child),
          ]),
        )),
      ),
    );
  }
}
class _NavigateIntent extends Intent { const _NavigateIntent(this.path); final String path; }
class _AddIntent extends Intent { const _AddIntent(); }
