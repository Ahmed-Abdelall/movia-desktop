import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/strings.dart';
import '../../updates/update_service.dart';
import '../../widget/widget_window.dart';
import '../application/event_providers.dart';
import '../domain/event.dart';

const categoryColors = <String, int>{
  'personal': 0xFF7C3AED,
  'work': 0xFF2563EB,
  'birthday': 0xFFDB2777,
  'travel': 0xFF0891B2,
  'education': 0xFF16803D,
  'finance': 0xFFB45309,
  'health': 0xFFDC2626,
  'other': 0xFF64748B,
};
IconData eventIcon(String value) => switch (value) {
  'personal' => Icons.person_outline,
  'work' => Icons.work_outline,
  'birthday' => Icons.cake_outlined,
  'travel' => Icons.flight_outlined,
  'education' => Icons.school_outlined,
  'finance' => Icons.savings_outlined,
  'health' => Icons.favorite_outline,
  _ => Icons.event_outlined,
};
String localeName(BuildContext c) => Localizations.localeOf(c).toLanguageTag();
String formatDate(BuildContext c, DateTime date) =>
    DateFormat.yMMMMEEEEd(localeName(c)).add_jm().format(date.toLocal());
String formatStamp(BuildContext c, DateTime date) =>
    DateFormat.yMMMMd(localeName(c)).add_jm().format(date.toLocal());

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<DashboardScreen> {
  String query = '', sort = 'soonest';
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ref
      .watch(eventsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          var events = all
              .where(
                (e) =>
                    !e.archived &&
                    e.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          events.sort(
            (a, b) => sort == 'name'
                ? a.title.compareTo(b.title)
                : sort == 'latest'
                ? b.targetInstant.compareTo(a.targetInstant)
                : a.targetInstant.compareTo(b.targetInstant),
          );
          final next = events
              .where((e) => e.targetInstant.isAfter(DateTime.now()))
              .firstOrNull;
          return Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => query = v),
                        decoration: InputDecoration(
                          hintText: s(context).t('search'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownMenu<String>(
                      initialSelection: sort,
                      width: 175,
                      leadingIcon: const Icon(Icons.sort),
                      onSelected: (v) {
                        if (v != null) setState(() => sort = v);
                      },
                      dropdownMenuEntries: ['soonest', 'latest', 'name']
                          .map(
                            (v) => DropdownMenuEntry(
                              value: v,
                              label: s(context).t(v),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: WidgetWindowService.open,
                      icon: const Icon(Icons.widgets_outlined),
                      label: Text(s(context).t('openWidget')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => showEventEditor(context),
                      icon: const Icon(Icons.add),
                      label: Text(s(context).t('add')),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 56),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final main = Column(
                        children: [
                          if (next != null)
                            CountdownPanel(event: next)
                          else
                            EmptyState(
                              icon: Icons.hourglass_empty_rounded,
                              title: s(
                                context,
                              ).t(query.isEmpty ? 'empty' : 'noMatches'),
                              message: s(context).t(
                                query.isEmpty
                                    ? 'emptyMessage'
                                    : 'searchMessage',
                              ),
                              action: query.isEmpty
                                  ? s(context).t('add')
                                  : null,
                              onAction: query.isEmpty
                                  ? () => showEventEditor(context)
                                  : null,
                            ),
                          const SizedBox(height: 18),
                          Expanded(child: EventTimeline(events: events)),
                        ],
                      );
                      if (box.maxWidth < 960) return main;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: main),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 340,
                            child: CalendarPanel(events: events),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class CountdownPanel extends StatelessWidget {
  const CountdownPanel({super.key, required this.event});
  final MoviaEvent event;
  @override
  Widget build(BuildContext context) {
    final d = event.targetInstant.difference(DateTime.now());
    final values = [
      d.inDays,
      d.inHours.remainder(24),
      d.inMinutes.remainder(60),
      d.inSeconds.remainder(60),
    ];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/event/${event.externalId}'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s(context).t('next'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  EventIcon(event: event, size: 58),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(formatDate(context, event.targetInstant)),
                        Text(
                          '${s(context).t('created')} ${formatStamp(context, event.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Column(
                      children: [
                        Text(
                          values[i].clamp(0, 999).toString().padLeft(2, '0'),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          s(
                            context,
                          ).t(['days', 'hours', 'minutes', 'seconds'][i]),
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
    );
  }
}

class EventTimeline extends StatelessWidget {
  const EventTimeline({super.key, required this.events});
  final List<MoviaEvent> events;
  @override
  Widget build(BuildContext context) {
    final groups = <String, List<MoviaEvent>>{};
    for (final event in events) {
      (groups.putIfAbsent(groupKey(event.targetInstant), () => [])).add(event);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s(context).t('upcoming'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              Expanded(child: Center(child: Text(s(context).t('noMatches'))))
            else
              Expanded(
                child: ListView(
                  children: [
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          top: 12,
                          bottom: 4,
                        ),
                        child: Text(
                          s(context).t(entry.key),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      for (final event in entry.value) EventRow(event: event),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String groupKey(DateTime target, {DateTime? now}) {
  final n = now ?? DateTime.now(), d = target.toLocal();
  final today = DateTime(n.year, n.month, n.day),
      day = DateTime(d.year, d.month, d.day);
  final delta = day.difference(today).inDays;
  if (delta <= 0) return 'today';
  if (delta == 1) return 'tomorrow';
  final endWeek = today.add(Duration(days: 7 - today.weekday));
  if (!day.isAfter(endWeek)) return 'thisWeek';
  if (day.year == today.year && day.month == today.month) return 'thisMonth';
  return 'later';
}

class EventRow extends ConsumerWidget {
  const EventRow({super.key, required this.event});
  final MoviaEvent event;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: EventIcon(event: event, size: 42),
    title: Text(event.title),
    subtitle: Text(
      '${DateFormat.yMMMd(localeName(context)).add_jm().format(event.targetInstant.toLocal())}'
      '  •  ${s(context).t('created')} ${DateFormat.yMMMd(localeName(context)).format(event.createdAt.toLocal())}',
    ),
    onTap: () => context.push('/event/${event.externalId}'),
    trailing: PopupMenuButton<String>(
      tooltip: s(context).t('actions'),
      onSelected: (v) => eventAction(context, ref, event, v),
      itemBuilder: (_) =>
          ['open', 'edit', 'duplicate', 'archive', 'export', 'delete']
              .map((v) => PopupMenuItem(value: v, child: Text(s(context).t(v))))
              .toList(),
    ),
  );
}

Future<void> eventAction(
  BuildContext context,
  WidgetRef ref,
  MoviaEvent event,
  String value,
) async {
  if (value == 'open') context.push('/event/${event.externalId}');
  if (value == 'edit') await showEventEditor(context, event: event);
  if (value == 'duplicate') {
    await ref.read(eventsProvider.notifier).duplicate(event, const Uuid().v4());
  }
  if (value == 'archive') {
    await ref.read(eventsProvider.notifier).archive(event, true);
  }
  if (!context.mounted) return;
  if (value == 'delete') await confirmDelete(context, ref, event);
  if (value == 'export') {
    final path = await getSaveLocation(
      suggestedName: '${event.title}.json',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (path != null) {
      await File(path.path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(event.toJson()),
      );
    }
  }
}

class EventIcon extends StatelessWidget {
  const EventIcon({super.key, required this.event, required this.size});
  final MoviaEvent event;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Color(event.colorArgb).withValues(alpha: .14),
      borderRadius: BorderRadius.circular(size / 3),
    ),
    child: Icon(
      eventIcon(event.icon),
      color: Color(event.colorArgb),
      size: size * .55,
    ),
  );
}

class CalendarPanel extends StatelessWidget {
  const CalendarPanel({super.key, required this.events});
  final List<MoviaEvent> events;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now(), first = DateTime(now.year, now.month, 1);
    final count = DateTime(now.year, now.month + 1, 0).day;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMM(localeName(context)).format(now),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              itemCount: first.weekday - 1 + count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemBuilder: (_, i) {
                if (i < first.weekday - 1) return const SizedBox();
                final day = i - first.weekday + 2;
                final match = events.where((e) {
                  final d = e.targetInstant.toLocal();
                  return d.year == now.year &&
                      d.month == now.month &&
                      d.day == day;
                }).firstOrNull;
                return InkWell(
                  onTap: match == null
                      ? null
                      : () => context.push('/event/${match.externalId}'),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: match == null
                          ? null
                          : BoxDecoration(
                              color: Color(
                                match.colorArgb,
                              ).withValues(alpha: .2),
                              shape: BoxShape.circle,
                            ),
                      child: Text('$day'),
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            if (events.isEmpty)
              EmptyState(
                icon: Icons.calendar_today_outlined,
                title: s(context).t('calendarEmpty'),
                message: s(context).t('calendarMessage'),
              ),
          ],
        ),
      ),
    );
  }
}

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(eventsProvider).value?.where((e) => !e.archived).toList() ??
        [];
    return Padding(
      padding: const EdgeInsets.all(28),
      child: CalendarPanel(events: events),
    );
  }
}

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events =
        ref.watch(eventsProvider).value?.where((e) => e.archived).toList() ??
        [];
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s(context).t('archive'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: events.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: s(context).t('noArchived'),
                      message: s(context).t('archiveMessage'),
                    )
                  : ListView(
                      children: events
                          .map(
                            (e) => ListTile(
                              leading: EventIcon(event: e, size: 42),
                              title: Text(e.title),
                              onTap: () =>
                                  context.push('/event/${e.externalId}'),
                              trailing: TextButton.icon(
                                onPressed: () => ref
                                    .read(eventsProvider.notifier)
                                    .archive(e, false),
                                icon: const Icon(Icons.restore),
                                label: Text(s(context).t('restore')),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref
        .watch(eventsProvider)
        .value
        ?.where((e) => e.externalId == id)
        .firstOrNull;
    if (event == null) return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(28),
      child: ListView(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EventIcon(event: event, size: 70),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showEventEditor(context, event: event),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(s(context).t('edit')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    formatDate(context, event.targetInstant),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(event.description.isEmpty ? '—' : event.description),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      Text(
                        '${s(context).t('created')}: ${formatStamp(context, event.createdAt)}',
                      ),
                      Text(
                        '${s(context).t('updated')}: ${formatStamp(context, event.updatedAt)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  CountdownPanel(event: event),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(eventsProvider.notifier)
                              .archive(event, !event.archived);
                          if (context.mounted) context.pop();
                        },
                        icon: Icon(
                          event.archived
                              ? Icons.restore
                              : Icons.inventory_2_outlined,
                        ),
                        label: Text(
                          s(context).t(event.archived ? 'restore' : 'archive'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => confirmDelete(context, ref, event),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(s(context).t('delete')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> confirmDelete(
  BuildContext context,
  WidgetRef ref,
  MoviaEvent event,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(s(c).t('delete')),
      content: Text(s(c).t('confirmDelete')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(s(c).t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(s(c).t('delete')),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(eventsProvider.notifier).delete(event.externalId);
    if (context.mounted && context.canPop()) context.pop();
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  UpdateResult result = const UpdateResult(UpdateStatus.idle);
  double progress = 0;
  bool cancelled = false;
  bool installedBuild = false;
  @override
  void initState() {
    super.initState();
    isInstalledBuild().then((value) {
      if (mounted) setState(() => installedBuild = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const SettingsState();
    final events =
        ref.watch(eventsProvider).value?.where((e) => !e.archived).toList() ??
        [];
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text(
          s(context).t('settings'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        section(context, 'appearance', [
          SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text(s(context).t('system')),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text(s(context).t('light')),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                label: Text(s(context).t('dark')),
              ),
            ],
            selected: {settings.theme},
            onSelectionChanged: (v) =>
                ref.read(settingsProvider.notifier).setTheme(v.first),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'en', label: Text('English')),
              ButtonSegment(value: 'ar', label: Text('العربية')),
            ],
            selected: {settings.language},
            onSelectionChanged: (v) =>
                ref.read(settingsProvider.notifier).setLanguage(v.first),
          ),
        ]),
        section(context, 'desktopWidget', [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: WidgetWindowService.open,
                icon: const Icon(Icons.open_in_new),
                label: Text(s(context).t('openWidget')),
              ),
              DropdownMenu<WidgetStyle>(
                initialSelection: settings.widgetStyle,
                label: Text(s(context).t('widgetStyle')),
                onSelected: (v) {
                  if (v != null) _save(settings.copyWith(widgetStyle: v));
                },
                dropdownMenuEntries: WidgetStyle.values
                    .map(
                      (v) => DropdownMenuEntry(
                        value: v,
                        label: s(context).t(v.name),
                      ),
                    )
                    .toList(),
              ),
              DropdownMenu<String>(
                initialSelection: settings.widgetEventId,
                label: Text(s(context).t('selectedEvent')),
                onSelected: (v) => _save(settings.copyWith(widgetEventId: v)),
                dropdownMenuEntries: events
                    .map(
                      (e) => DropdownMenuEntry(
                        value: e.externalId,
                        label: e.title,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          SwitchListTile(
            value: settings.widgetAlwaysOnTop,
            title: Text(s(context).t('alwaysOnTop')),
            onChanged: (v) => _save(settings.copyWith(widgetAlwaysOnTop: v)),
          ),
          SwitchListTile(
            value: settings.widgetLocked,
            title: Text(s(context).t('lockPosition')),
            onChanged: (v) => _save(settings.copyWith(widgetLocked: v)),
          ),
          ListTile(
            title: Text(s(context).t('opacity')),
            subtitle: Slider(
              value: settings.widgetOpacity,
              min: .55,
              max: 1,
              onChanged: (v) => _save(settings.copyWith(widgetOpacity: v)),
            ),
          ),
          SwitchListTile(
            value: settings.startWidgetWithMovia,
            title: Text(s(context).t('startWidget')),
            onChanged: (v) => _save(settings.copyWith(startWidgetWithMovia: v)),
          ),
          SwitchListTile(
            value: settings.startWithWindows,
            title: Text(s(context).t('startWindows')),
            onChanged: (v) async {
              await setStartWithWindows(v);
              await _save(settings.copyWith(startWithWindows: v));
            },
          ),
        ]),
        section(context, 'applicationUpdates', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${s(context).t('currentVersion')}: $currentVersion'),
            subtitle: Text(
              settings.lastUpdateCheck == null
                  ? s(context).t('neverChecked')
                  : '${s(context).t('lastChecked')}: ${formatStamp(context, settings.lastUpdateCheck!)}',
            ),
            trailing: FilledButton.tonal(
              onPressed: result.status == UpdateStatus.checking
                  ? null
                  : () => _check(settings),
              child: Text(s(context).t('checkUpdates')),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.automaticUpdates,
            title: Text(s(context).t('automaticUpdates')),
            onChanged: (v) => _save(settings.copyWith(automaticUpdates: v)),
          ),
          Text(_updateMessage(context, result)),
          if (!installedBuild)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(s(context).t('portableUpdateMessage')),
            ),
          if (result.status == UpdateStatus.downloading)
            LinearProgressIndicator(value: progress),
          if (result.release != null)
            Wrap(
              spacing: 12,
              children: [
                if (installedBuild)
                  FilledButton(
                    onPressed: () => _download(result.release!),
                    child: Text(s(context).t('downloadInstall')),
                  ),
                TextButton(
                  onPressed: () =>
                      launchUrl(Uri.parse(result.release!.pageUrl)),
                  child: Text(s(context).t('viewRelease')),
                ),
              ],
            ),
        ]),
        section(context, 'data', [
          Wrap(
            spacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.file_open),
                label: Text(s(context).t('import')),
              ),
              OutlinedButton.icon(
                onPressed: () => _export(context, settings),
                icon: const Icon(Icons.save_alt),
                label: Text(s(context).t('export')),
              ),
            ],
          ),
        ]),
        section(context, 'about', [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.hourglass_bottom_rounded),
            title: Text('Movia Desktop'),
            subtitle: Text('Version 1.1.0 • MIT License'),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(repositoryUrl)),
            child: const Text(repositoryUrl),
          ),
        ]),
      ],
    );
  }

  Widget section(BuildContext c, String key, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s(c).t(key), style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
  Future<void> _save(SettingsState s2) async {
    await ref.read(settingsProvider.notifier).updateSettings(s2);
    await WidgetWindowService.sync();
  }

  Future<void> _check(SettingsState settings) async {
    setState(() => result = const UpdateResult(UpdateStatus.checking));
    final r = await UpdateService().check();
    await _save(settings.copyWith(lastUpdateCheck: DateTime.now()));
    if (mounted) setState(() => result = r);
  }

  Future<void> _download(ReleaseInfo release) async {
    cancelled = false;
    setState(
      () => result = UpdateResult(UpdateStatus.downloading, release: release),
    );
    try {
      final file = await UpdateService().download(release, (a, b) {
        if (mounted) setState(() => progress = b == null ? 0 : a / b);
      }, cancelled: () => cancelled);
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(s(c).t('installUpdate')),
          content: Text(s(c).t('installConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(s(c).t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(s(c).t('install')),
            ),
          ],
        ),
      );
      if (ok == true) {
        final launched = await UpdateService().launchInstaller(file);
        if (launched) {
          exit(0);
        }
        setState(
          () => result = UpdateResult(
            UpdateStatus.installerLaunchFailed,
            release: release,
          ),
        );
      } else {
        setState(
          () =>
              result = UpdateResult(UpdateStatus.downloaded, release: release),
        );
      }
    } on ChecksumMismatch {
      setState(
        () => result = UpdateResult(
          UpdateStatus.checksumMismatch,
          release: release,
        ),
      );
    } on UpdateCancelled {
      setState(
        () => result = UpdateResult(UpdateStatus.cancelled, release: release),
      );
    } catch (e) {
      setState(
        () => result = UpdateResult(
          UpdateStatus.downloadFailed,
          release: release,
          message: '$e',
        ),
      );
    }
  }

  Future<void> _export(BuildContext context, SettingsState settings) async {
    final path = await getSaveLocation(
      suggestedName:
          'movia-export-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (path == null) return;
    await File(path.path).writeAsString(
      await ref
          .read(repositoryProvider)
          .exportJson(settings.theme.name, settings.language),
    );
  }

  Future<void> _import(BuildContext context) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (file == null) return;
      final events = await ref
          .read(repositoryProvider)
          .parseImport(File(file.path));
      if (!context.mounted) return;
      final replace = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(s(c).t('preview')),
          content: Text('${events.length} ${s(c).t('events')}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(s(c).t('cancel')),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(s(c).t('merge')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(s(c).t('replace')),
            ),
          ],
        ),
      );
      if (replace == null) return;
      await ref.read(repositoryProvider).applyImport(events, replace: replace);
      await ref.read(eventsProvider.notifier).reload();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s(context).t('invalid'))));
      }
    }
  }

  String _updateMessage(BuildContext c, UpdateResult r) =>
      s(c).t('update_${r.status.name}');
}

Future<void> showEventEditor(BuildContext context, {MoviaEvent? event}) async =>
    showDialog(
      context: context,
      builder: (_) => EventEditor(event: event),
    );

class EventEditor extends ConsumerStatefulWidget {
  const EventEditor({super.key, this.event});
  final MoviaEvent? event;
  @override
  ConsumerState<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<EventEditor> {
  late final TextEditingController title, description;
  late DateTime date;
  late TimeOfDay time;
  String icon = 'personal';
  bool dirty = false, allowClose = false;
  @override
  void initState() {
    super.initState();
    final e = widget.event;
    title = TextEditingController(text: e?.title);
    description = TextEditingController(text: e?.description);
    final d =
        e?.targetInstant.toLocal() ??
        DateTime.now().add(const Duration(days: 7));
    date = d;
    time = TimeOfDay.fromDateTime(d);
    icon = e?.icon ?? 'personal';
    title.addListener(_dirty);
    description.addListener(_dirty);
  }

  void _dirty() {
    if (!dirty && mounted) setState(() => dirty = true);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<bool> _discard() async {
    if (!dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(s(c).t('discardTitle')),
            content: Text(s(c).t('discardMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(s(c).t('keepEditing')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(s(c).t('discard')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowClose || !dirty,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _discard()) {
        allowClose = true;
        if (context.mounted) Navigator.pop(context);
      }
    },
    child: AlertDialog(
      title: Text(s(context).t(widget.event == null ? 'add' : 'edit')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: title,
                autofocus: true,
                decoration: InputDecoration(labelText: s(context).t('title')),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: s(context).t('description'),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final v = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 3650),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 36500),
                          ),
                          initialDate: date,
                        );
                        if (v != null) {
                          setState(() {
                            date = v;
                            dirty = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(DateFormat.yMMMd().format(date)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final v = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (v != null) {
                          setState(() {
                            time = v;
                            dirty = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownMenu<String>(
                width: 520,
                initialSelection: icon,
                label: Text(s(context).t('category')),
                onSelected: (v) {
                  if (v != null) {
                    setState(() {
                      icon = v;
                      dirty = true;
                    });
                  }
                },
                dropdownMenuEntries: categoryColors.keys
                    .map(
                      (v) => DropdownMenuEntry(
                        value: v,
                        label: s(context).t(v),
                        leadingIcon: Icon(
                          eventIcon(v),
                          color: Color(categoryColors[v]!),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (await _discard()) {
              allowClose = true;
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Text(s(context).t('cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(s(context).t('save'))),
      ],
    ),
  );
  Future<void> _save() async {
    if (title.text.trim().isEmpty) return;
    final target = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final now = DateTime.now().toUtc(), original = widget.event;
    final e = MoviaEvent(
      externalId: original?.externalId ?? const Uuid().v4(),
      title: title.text.trim(),
      description: description.text.trim(),
      targetInstant: target,
      timeZone: original?.timeZone ?? 'Asia/Dubai',
      colorArgb: categoryColors[icon]!,
      icon: icon,
      archived: original?.archived ?? false,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(eventsProvider.notifier).save(e);
    allowClose = true;
    if (mounted) Navigator.pop(context);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
