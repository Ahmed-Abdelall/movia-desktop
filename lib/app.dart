import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'core/localization/strings.dart';
import 'core/design/movia_design.dart';
import 'features/events/application/event_providers.dart';
import 'features/events/presentation/screens.dart';
import 'features/updates/update_service.dart';
import 'features/updates/deployment_mode.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
        GoRoute(path: '/archive', builder: (_, _) => const ArchiveScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: '/event/:id',
          builder: (_, state) =>
              EventDetailsScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

Future<Object?> handleMainWindowMessage(MethodCall call) async {
  await windowManager.show();
  await windowManager.focus();
  if (call.method == 'openEvent' && call.arguments is String) {
    router.push('/event/${call.arguments}');
  } else if (call.method == 'openSettings') {
    router.go('/settings');
  }
  return null;
}

Future<bool> navigateBack(BuildContext context) async {
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
    return true;
  }
  if (router.canPop()) {
    router.pop();
    return true;
  }
  return false;
}

class MoviaApp extends ConsumerStatefulWidget {
  const MoviaApp({super.key});
  @override
  ConsumerState<MoviaApp> createState() => _MoviaAppState();
}

class _MoviaAppState extends ConsumerState<MoviaApp> {
  bool updateScheduled = false;
  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value ?? const SettingsState();
    if (!updateScheduled && asyncSettings.hasValue) {
      updateScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _automaticCheck(settings),
      );
    }
    final themeMode = switch (settings.theme) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final locale = switch (settings.language) {
      'en' => const Locale('en'),
      'ar' => const Locale('ar'),
      _ => null,
    };
    return MaterialApp.router(
      title: 'Movia',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: MoviaDesign.theme(Brightness.light),
      darkTheme: MoviaDesign.theme(Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  Future<void> _automaticCheck(SettingsState settings) async {
    if (!settings.automaticUpdates ||
        (settings.lastUpdateCheck != null &&
            DateTime.now().difference(settings.lastUpdateCheck!).inHours <
                24)) {
      return;
    }
    final deployment = await DeploymentModeService.current();
    final result = await UpdateService(mode: deployment.mode).check();
    await ref
        .read(settingsProvider.notifier)
        .updateSettings(settings.copyWith(lastUpdateCheck: DateTime.now()));
    if (!mounted || result.status != UpdateStatus.available) return;
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s(context).t('updateAvailableMessage')),
          action: SnackBarAction(
            label: s(context).t('view'),
            onPressed: () => router.go('/settings'),
          ),
        ),
      );
    }
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final items = [
      ('overview', Icons.grid_view_rounded, '/dashboard'),
      ('calendar', Icons.calendar_month_outlined, '/calendar'),
      ('events', Icons.event_note_outlined, '/dashboard'),
      ('archive', Icons.inventory_2_outlined, '/archive'),
      ('settings', Icons.settings_outlined, '/settings'),
    ];
    final selected = location.startsWith('/event')
        ? 2
        : items.indexWhere((e) => location.startsWith(e.$3));
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.digit1, control: true):
            const _NavigateIntent('/dashboard'),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true):
            const _NavigateIntent('/calendar'),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true):
            const _NavigateIntent('/archive'),
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            const _NavigateIntent('/settings'),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const _AddIntent(),
        const SingleActivator(LogicalKeyboardKey.escape): const _BackIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            const _BackIntent(),
      },
      child: Actions(
        actions: {
          _NavigateIntent: CallbackAction<_NavigateIntent>(
            onInvoke: (i) => context.go(i.path),
          ),
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_) => showEventEditor(context),
          ),
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) => navigateBack(context),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                Container(
                  width: 236,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    border: BorderDirectional(
                      end: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    MoviaDesign.purple,
                                    MoviaDesign.blue,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.hourglass_bottom_rounded,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Movia',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...List.generate(items.length, (i) {
                        final item = items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          child: ListTile(
                            selected: selected == i,
                            leading: Icon(item.$2),
                            title: Text(s(context).t(item.$1)),
                            trailing: i == 2
                                ? null
                                : Text(
                                    i < 2
                                        ? 'Ctrl+${i + 1}'
                                        : i == 4
                                        ? 'Ctrl+,'
                                        : '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => context.go(item.$3),
                          ),
                        );
                      }),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Movia 1.2.1  •  ${s(context).t('windowsPlatform')}\n${s(context).t('localDataMessage')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigateIntent extends Intent {
  const _NavigateIntent(this.path);
  final String path;
}

class _AddIntent extends Intent {
  const _AddIntent();
}

class _BackIntent extends Intent {
  const _BackIntent();
}
