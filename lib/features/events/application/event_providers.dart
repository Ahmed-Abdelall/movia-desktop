import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../updates/update_service.dart';

final repositoryProvider = Provider((_) => EventRepository());
final eventsProvider =
    AsyncNotifierProvider<EventsController, List<MoviaEvent>>(
      EventsController.new,
    );

class EventsController extends AsyncNotifier<List<MoviaEvent>> {
  @override
  Future<List<MoviaEvent>> build() => ref.read(repositoryProvider).all();
  Future<void> save(MoviaEvent event) async {
    final existing = state.value
        ?.where((e) => e.externalId == event.externalId)
        .firstOrNull;
    final now = DateTime.now().toUtc();
    await ref
        .read(repositoryProvider)
        .save(
          event.copyWith(
            createdAt: existing?.createdAt ?? event.createdAt,
            updatedAt: now,
          ),
        );
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(repositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> archive(MoviaEvent event, bool value) =>
      save(event.copyWith(archived: value));
  Future<MoviaEvent> duplicate(MoviaEvent event, String id) async {
    final now = DateTime.now().toUtc();
    final copy = MoviaEvent(
      externalId: id,
      title: '${event.title} (Copy)',
      description: event.description,
      targetInstant: event.targetInstant,
      timeZone: event.timeZone,
      colorArgb: event.colorArgb,
      icon: event.icon,
      createdAt: now,
      updatedAt: now,
    );
    await save(copy);
    return copy;
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

enum AppThemeMode { system, light, dark }

enum WidgetStyle { compact, countdown, upcoming }

class SettingsState {
  const SettingsState({
    this.theme = AppThemeMode.system,
    this.language = 'system',
    this.widgetStyle = WidgetStyle.compact,
    this.widgetEventId,
    this.widgetAlwaysOnTop = true,
    this.widgetLocked = false,
    this.widgetOpacity = .92,
    this.startWidgetWithMovia = false,
    this.startWithWindows = false,
    this.automaticUpdates = true,
    this.lastUpdateCheck,
  });
  final AppThemeMode theme;
  final String language;
  final WidgetStyle widgetStyle;
  final String? widgetEventId;
  final bool widgetAlwaysOnTop,
      widgetLocked,
      startWidgetWithMovia,
      startWithWindows,
      automaticUpdates;
  final double widgetOpacity;
  final DateTime? lastUpdateCheck;
  SettingsState copyWith({
    AppThemeMode? theme,
    String? language,
    WidgetStyle? widgetStyle,
    String? widgetEventId,
    bool clearWidgetEventId = false,
    bool? widgetAlwaysOnTop,
    bool? widgetLocked,
    double? widgetOpacity,
    bool? startWidgetWithMovia,
    bool? startWithWindows,
    bool? automaticUpdates,
    DateTime? lastUpdateCheck,
  }) => SettingsState(
    theme: theme ?? this.theme,
    language: language ?? this.language,
    widgetStyle: widgetStyle ?? this.widgetStyle,
    widgetEventId: clearWidgetEventId
        ? null
        : widgetEventId ?? this.widgetEventId,
    widgetAlwaysOnTop: widgetAlwaysOnTop ?? this.widgetAlwaysOnTop,
    widgetLocked: widgetLocked ?? this.widgetLocked,
    widgetOpacity: widgetOpacity ?? this.widgetOpacity,
    startWidgetWithMovia: startWidgetWithMovia ?? this.startWidgetWithMovia,
    startWithWindows: startWithWindows ?? this.startWithWindows,
    automaticUpdates: automaticUpdates ?? this.automaticUpdates,
    lastUpdateCheck: lastUpdateCheck ?? this.lastUpdateCheck,
  );
}

final settingsProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      theme: AppThemeMode.values.byName(prefs.getString('theme') ?? 'system'),
      language: prefs.getString('language') ?? 'system',
      widgetStyle: WidgetStyle.values.byName(
        prefs.getString('widgetStyle') ?? 'compact',
      ),
      widgetEventId: prefs.getString('widgetEventId'),
      widgetAlwaysOnTop: prefs.getBool('widgetAlwaysOnTop') ?? true,
      widgetLocked: prefs.getBool('widgetLocked') ?? false,
      widgetOpacity: prefs.getDouble('widgetOpacity') ?? .92,
      startWidgetWithMovia: prefs.getBool('startWidgetWithMovia') ?? false,
      startWithWindows: prefs.getBool('startWithWindows') ?? false,
      automaticUpdates:
          prefs.getBool('automaticUpdates') ?? await isInstalledBuild(),
      lastUpdateCheck: DateTime.tryParse(
        prefs.getString('lastUpdateCheck') ?? '',
      ),
    );
  }

  Future<void> setTheme(AppThemeMode value) async {
    state = AsyncData(
      (state.value ?? const SettingsState()).copyWith(theme: value),
    );
    await (await SharedPreferences.getInstance()).setString(
      'theme',
      value.name,
    );
  }

  Future<void> setLanguage(String value) async {
    state = AsyncData(
      (state.value ?? const SettingsState()).copyWith(language: value),
    );
    await (await SharedPreferences.getInstance()).setString('language', value);
  }

  Future<void> updateSettings(SettingsState value) async {
    state = AsyncData(value);
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setString('widgetStyle', value.widgetStyle.name),
      if (value.widgetEventId == null)
        p.remove('widgetEventId')
      else
        p.setString('widgetEventId', value.widgetEventId!),
      p.setBool('widgetAlwaysOnTop', value.widgetAlwaysOnTop),
      p.setBool('widgetLocked', value.widgetLocked),
      p.setDouble('widgetOpacity', value.widgetOpacity),
      p.setBool('startWidgetWithMovia', value.startWidgetWithMovia),
      p.setBool('startWithWindows', value.startWithWindows),
      p.setBool('automaticUpdates', value.automaticUpdates),
      if (value.lastUpdateCheck != null)
        p.setString(
          'lastUpdateCheck',
          value.lastUpdateCheck!.toUtc().toIso8601String(),
        ),
    ]);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}
