import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/localization/strings.dart';
import '../events/application/event_providers.dart';
import '../events/domain/event.dart';

class WidgetWindowService {
  static Future<void> open() async {
    final existing = (await WindowController.getAll())
        .where((w) => w.arguments == 'movia-widget')
        .firstOrNull;
    if (existing != null) {
      await existing.show();
      return;
    }
    await WindowController.create(
      const WindowConfiguration(
        arguments: 'movia-widget',
        hiddenAtLaunch: false,
      ),
    );
  }

  static Future<void> sync() async {
    final widget = (await WindowController.getAll())
        .where((w) => w.arguments == 'movia-widget')
        .firstOrNull;
    await widget?.invokeMethod('refresh');
  }
}

Future<void> configureWidgetWindow() async {
  await windowManager.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final width = prefs.getDouble('widgetWidth') ?? 390;
  final height = prefs.getDouble('widgetHeight') ?? 190;
  final x = prefs.getDouble('widgetX');
  final y = prefs.getDouble('widgetY');
  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      size: Size(width, height),
      minimumSize: const Size(300, 130),
      center: x == null || y == null,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      skipTaskbar: false,
    ),
    () async {
      if (x != null && y != null) await windowManager.setPosition(Offset(x, y));
      await windowManager.setAlwaysOnTop(
        prefs.getBool('widgetAlwaysOnTop') ?? true,
      );
      await windowManager.setResizable(
        !(prefs.getBool('widgetLocked') ?? false),
      );
      await windowManager.show();
    },
  );
}

class WidgetApp extends ConsumerWidget {
  const WidgetApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const SettingsState();
    final locale = settings.language == 'ar'
        ? const Locale('ar')
        : settings.language == 'en'
        ? const Locale('en')
        : null;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6255E7)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B83FF),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: switch (settings.theme) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const DesktopWidgetWindow(),
    );
  }
}

class DesktopWidgetWindow extends ConsumerStatefulWidget {
  const DesktopWidgetWindow({super.key});
  @override
  ConsumerState<DesktopWidgetWindow> createState() =>
      _DesktopWidgetWindowState();
}

class _DesktopWidgetWindowState extends ConsumerState<DesktopWidgetWindow>
    with WindowListener {
  Timer? _clock, _refresh;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WindowController.fromCurrentEngine().then((controller) {
      controller.setWindowMethodHandler((call) async {
        if (call.method == 'refresh') {
          await ref.read(settingsProvider.notifier).reload();
          await ref.read(eventsProvider.notifier).reload();
          final settings =
              ref.read(settingsProvider).value ?? const SettingsState();
          await windowManager.setAlwaysOnTop(settings.widgetAlwaysOnTop);
          await windowManager.setResizable(!settings.widgetLocked);
          if (mounted) setState(() {});
        }
        return null;
      });
    });
    _refresh = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ref.read(eventsProvider.notifier).reload(),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _refresh?.cancel();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMove() => _persistBounds();
  @override
  void onWindowResize() => _persistBounds();
  Future<void> _persistBounds() async {
    final p = await SharedPreferences.getInstance();
    final pos = await windowManager.getPosition(),
        size = await windowManager.getSize();
    await Future.wait([
      p.setDouble('widgetX', pos.dx),
      p.setDouble('widgetY', pos.dy),
      p.setDouble('widgetWidth', size.width),
      p.setDouble('widgetHeight', size.height),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const SettingsState();
    if (settings.widgetStyle == WidgetStyle.countdown && _clock == null) {
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (settings.widgetStyle != WidgetStyle.countdown) {
      _clock?.cancel();
      _clock = null;
    }
    final all = ref.watch(eventsProvider).value ?? const <MoviaEvent>[];
    final active =
        all
            .where(
              (e) => !e.archived && e.targetInstant.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.targetInstant.compareTo(b.targetInstant));
    final selected =
        active
            .where((e) => e.externalId == settings.widgetEventId)
            .firstOrNull ??
        active.firstOrNull;
    if (selected != null && selected.externalId != settings.widgetEventId) {
      Future.microtask(
        () => ref
            .read(settingsProvider.notifier)
            .updateSettings(
              settings.copyWith(widgetEventId: selected.externalId),
            ),
      );
    }
    return Directionality(
      textDirection: settings.language == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: GestureDetector(
        onPanStart: settings.widgetLocked
            ? null
            : (_) => windowManager.startDragging(),
        onDoubleTap: selected == null
            ? null
            : () => _openInMain(selected.externalId),
        onSecondaryTapDown: (d) => _menu(d.globalPosition, settings, active),
        child: Opacity(
          opacity: settings.widgetOpacity,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: const [
                  BoxShadow(blurRadius: 14, color: Color(0x22000000)),
                ],
              ),
              child: selected == null
                  ? _empty(context)
                  : settings.widgetStyle == WidgetStyle.upcoming
                  ? _upcoming(active.take(3).toList())
                  : settings.widgetStyle == WidgetStyle.countdown
                  ? _countdown(selected)
                  : _compact(selected),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.hourglass_empty_rounded, size: 34),
        Text(s(context).t('widgetNoEvent')),
        TextButton(
          onPressed: _openSettings,
          child: Text(s(context).t('selectEvent')),
        ),
      ],
    ),
  );
  Widget _compact(MoviaEvent e) => Row(
    children: [
      Icon(_eventIcon(e.icon), size: 38, color: Color(e.colorArgb)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(DateFormat.yMMMd().format(e.targetInstant.toLocal())),
          ],
        ),
      ),
      Text(
        '${e.targetInstant.difference(DateTime.now()).inDays}\n${s(context).t('days')}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ],
  );
  Widget _countdown(MoviaEvent e) {
    final d = e.targetInstant.difference(DateTime.now());
    final values = [
      d.inDays,
      d.inHours.remainder(24),
      d.inMinutes.remainder(60),
      d.inSeconds.remainder(60),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          e.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: values
              .map(
                (v) => Text(
                  v.clamp(0, 999).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        Text(DateFormat.yMMMd().add_jm().format(e.targetInstant.toLocal())),
      ],
    );
  }

  Widget _upcoming(List<MoviaEvent> events) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: events
        .map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(_eventIcon(e.icon), color: Color(e.colorArgb)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${e.targetInstant.difference(DateTime.now()).inDays} ${s(context).t('days')}',
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
  Future<void> _menu(
    Offset pos,
    SettingsState settings,
    List<MoviaEvent> events,
  ) async {
    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        for (final style in WidgetStyle.values)
          PopupMenuItem(
            value: 'style:${style.name}',
            child: Text(s(context).t(style.name)),
          ),
        PopupMenuItem(value: 'top', child: Text(s(context).t('alwaysOnTop'))),
        PopupMenuItem(value: 'lock', child: Text(s(context).t('lockPosition'))),
        PopupMenuItem(
          value: 'select',
          child: Text(s(context).t('selectEvent')),
        ),
        PopupMenuItem(value: 'close', child: Text(s(context).t('close'))),
      ],
    );
    if (value == null) return;
    if (value.startsWith('style:')) {
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(
            settings.copyWith(
              widgetStyle: WidgetStyle.values.byName(value.substring(6)),
            ),
          );
    } else if (value == 'top') {
      final next = !settings.widgetAlwaysOnTop;
      await windowManager.setAlwaysOnTop(next);
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(settings.copyWith(widgetAlwaysOnTop: next));
    } else if (value == 'lock') {
      final next = !settings.widgetLocked;
      await windowManager.setResizable(!next);
      await ref
          .read(settingsProvider.notifier)
          .updateSettings(settings.copyWith(widgetLocked: next));
    } else if (value == 'select') {
      await _openSettings();
    } else if (value == 'close') {
      await windowManager.close();
    }
  }

  Future<void> _openSettings() async {
    final main = (await WindowController.getAll())
        .where((w) => w.arguments.isEmpty)
        .firstOrNull;
    await main?.invokeMethod('openSettings');
  }

  Future<void> _openInMain(String id) async {
    final main = (await WindowController.getAll())
        .where((w) => w.arguments.isEmpty)
        .firstOrNull;
    await main?.invokeMethod('openEvent', id);
  }
}

IconData _eventIcon(String value) => switch (value) {
  'work' => Icons.work_outline,
  'travel' => Icons.flight_outlined,
  'health' => Icons.favorite_outline,
  'birthday' => Icons.cake_outlined,
  'education' => Icons.school_outlined,
  'finance' => Icons.savings_outlined,
  _ => Icons.event_outlined,
};

Future<void> setStartWithWindows(bool enabled) async {
  if (!Platform.isWindows) return;
  const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  if (enabled) {
    await Process.run('reg.exe', [
      'add',
      key,
      '/v',
      'Movia Desktop',
      '/t',
      'REG_SZ',
      '/d',
      '"${Platform.resolvedExecutable}"',
      '/f',
    ]);
  } else {
    await Process.run('reg.exe', ['delete', key, '/v', 'Movia Desktop', '/f']);
  }
}
