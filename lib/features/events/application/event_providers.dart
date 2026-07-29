import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';

final repositoryProvider = Provider((_) => EventRepository());
final eventsProvider = AsyncNotifierProvider<EventsController, List<MoviaEvent>>(EventsController.new);

class EventsController extends AsyncNotifier<List<MoviaEvent>> {
  @override
  Future<List<MoviaEvent>> build() => ref.read(repositoryProvider).all();
  Future<void> save(MoviaEvent event) async {
    await ref.read(repositoryProvider).save(event);
    ref.invalidateSelf();
    await future;
  }
  Future<void> delete(String id) async {
    await ref.read(repositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
  Future<void> archive(MoviaEvent event, bool value) => save(event.copyWith(archived: value));
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

enum AppThemeMode { system, light, dark }
class SettingsState {
  const SettingsState({this.theme = AppThemeMode.system, this.language = 'system'});
  final AppThemeMode theme;
  final String language;
  SettingsState copyWith({AppThemeMode? theme, String? language}) =>
      SettingsState(theme: theme ?? this.theme, language: language ?? this.language);
}
final settingsProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(SettingsController.new);
class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsState(
      theme: AppThemeMode.values.byName(prefs.getString('theme') ?? 'system'),
      language: prefs.getString('language') ?? 'system',
    );
  }
  Future<void> setTheme(AppThemeMode value) async {
    state = AsyncData((state.value ?? const SettingsState()).copyWith(theme: value));
    await (await SharedPreferences.getInstance()).setString('theme', value.name);
  }
  Future<void> setLanguage(String value) async {
    state = AsyncData((state.value ?? const SettingsState()).copyWith(language: value));
    await (await SharedPreferences.getInstance()).setString('language', value);
  }
}
