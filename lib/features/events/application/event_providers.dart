import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../updates/deployment_mode.dart';

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

class SettingsState {
  const SettingsState({
    this.theme = AppThemeMode.system,
    this.language = 'system',
    this.startWithWindows = false,
    this.automaticUpdates = true,
    this.lastUpdateCheck,
  });
  final AppThemeMode theme;
  final String language;
  final bool startWithWindows, automaticUpdates;
  final DateTime? lastUpdateCheck;
  SettingsState copyWith({
    AppThemeMode? theme,
    String? language,
    bool? startWithWindows,
    bool? automaticUpdates,
    DateTime? lastUpdateCheck,
  }) => SettingsState(
    theme: theme ?? this.theme,
    language: language ?? this.language,
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
    await Future.wait([
      for (final key in const [
        'widgetStyle',
        'widgetEventId',
        'widgetAlwaysOnTop',
        'widgetLocked',
        'widgetOpacity',
        'startWidgetWithMovia',
        'widgetX',
        'widgetY',
        'widgetWidth',
        'widgetHeight',
      ])
        prefs.remove(key),
    ]);
    return SettingsState(
      theme: AppThemeMode.values.byName(prefs.getString('theme') ?? 'system'),
      language: prefs.getString('language') ?? 'system',
      startWithWindows: prefs.getBool('startWithWindows') ?? false,
      automaticUpdates:
          prefs.getBool('automaticUpdates') ??
          (await DeploymentModeService.current()).mode !=
              DeploymentMode.standalonePortable,
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
