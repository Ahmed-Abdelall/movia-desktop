import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/localization/strings.dart';
import '../application/event_providers.dart';
import '../domain/event.dart';

IconData eventIcon(String value) => switch (value) {
  'travel' => Icons.flight_outlined, 'work' => Icons.work_outline,
  'health' => Icons.fitness_center, 'personal' => Icons.celebration_outlined,
  _ => Icons.event_outlined,
};

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override ConsumerState<DashboardScreen> createState() => _DashboardState();
}
class _DashboardState extends ConsumerState<DashboardScreen> {
  String query = ''; String sort = 'soonest'; Timer? timer;
  @override void initState() { super.initState(); timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final async = ref.watch(eventsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (all) {
        var events = all.where((e) => !e.archived && e.title.toLowerCase().contains(query.toLowerCase())).toList();
        events.sort((a,b) => sort == 'name' ? a.title.compareTo(b.title) :
          sort == 'latest' ? b.targetInstant.compareTo(a.targetInstant) : a.targetInstant.compareTo(b.targetInstant));
        final next = events.where((e) => e.targetInstant.isAfter(DateTime.now())).firstOrNull;
        return Padding(padding: const EdgeInsets.all(28), child: Column(children: [
          _Toolbar(onSearch: (v) => setState(() => query = v), sort: sort, onSort: (v) => setState(() => sort = v)),
          const SizedBox(height: 24),
          Expanded(child: LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 960;
            final main = Column(children: [
              if (next != null) CountdownPanel(event: next) else _EmptyPanel(),
              const SizedBox(height: 20),
              Expanded(child: _EventPanel(events: events)),
            ]);
            if (!wide) return main;
            return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: main), const SizedBox(width: 20),
              SizedBox(width: 360, child: CalendarPanel(events: events)),
            ]);
          })),
        ]));
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.onSearch, required this.sort, required this.onSort});
  final ValueChanged<String> onSearch, onSort; final String sort;
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextField(onChanged: onSearch, decoration: InputDecoration(
      hintText: s(context).t('search'), prefixIcon: const Icon(Icons.search), suffixText: 'Ctrl+K'))),
    const SizedBox(width: 12),
    DropdownMenu<String>(initialSelection: sort, width: 190, leadingIcon: const Icon(Icons.sort),
      onSelected: (v) { if (v != null) onSort(v); }, dropdownMenuEntries: [
        DropdownMenuEntry(value: 'soonest', label: s(context).t('soonest')),
        DropdownMenuEntry(value: 'latest', label: s(context).t('latest')),
        DropdownMenuEntry(value: 'name', label: s(context).t('name')),
      ]),
    const SizedBox(width: 12),
    FilledButton.icon(onPressed: () => showEventEditor(context), icon: const Icon(Icons.add),
      label: Text('${s(context).t('add')}   Ctrl+N'), style: FilledButton.styleFrom(minimumSize: const Size(170, 56))),
  ]);
}

class CountdownPanel extends StatelessWidget {
  const CountdownPanel({super.key, required this.event}); final MoviaEvent event;
  @override Widget build(BuildContext context) {
    final d = event.targetInstant.difference(DateTime.now());
    final parts = [d.inDays, d.inHours.remainder(24), d.inMinutes.remainder(60), d.inSeconds.remainder(60)];
    final labels = ['days','hours','minutes','seconds'];
    return Card(child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => context.go('/event/${event.externalId}'),
      child: Padding(padding: const EdgeInsets.all(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s(context).t('next'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Row(children: [
          _IconBox(event: event, size: 64), const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4), Text(DateFormat.yMMMMEEEEd().add_jm().format(event.targetInstant.toLocal())),
          ])),
        ]),
        const SizedBox(height: 22),
        Row(children: List.generate(4, (i) => Expanded(child: Container(
          decoration: i == 0 ? null : BoxDecoration(border: BorderDirectional(start: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
          child: Column(children: [
            Text(parts[i].clamp(0, 999).toString().padLeft(2,'0'), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
            Text(s(context).t(labels[i])),
          ]))))),
      ]))));
  }
}
class _EmptyPanel extends StatelessWidget {
  @override Widget build(BuildContext context) => Card(child: SizedBox(height: 230, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.event_available, size: 48, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 12), Text(s(context).t('empty'), style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16), FilledButton.icon(onPressed: () => showEventEditor(context), icon: const Icon(Icons.add), label: Text(s(context).t('add'))),
  ]))));
}
class _EventPanel extends StatelessWidget {
  const _EventPanel({required this.events}); final List<MoviaEvent> events;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.fromLTRB(22,20,22,8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(s(context).t('upcoming'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
    const SizedBox(height: 10), const Divider(height: 1),
    Expanded(child: events.isEmpty ? Center(child: Text(s(context).t('empty'))) : ListView.separated(
      itemCount: events.length, separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_,i) => EventTile(event: events[i]))),
  ])));
}

class EventTile extends ConsumerWidget {
  const EventTile({super.key, required this.event, this.archived = false});
  final MoviaEvent event; final bool archived;
  @override Widget build(BuildContext context, WidgetRef ref) {
    final row = ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
      leading: _IconBox(event: event, size: 48),
      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${s(context).t(event.icon)}  •  ${DateFormat.yMMMd().add_jm().format(event.targetInstant.toLocal())}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!archived) Text('${event.targetInstant.difference(DateTime.now()).inDays.clamp(0,999)} ${s(context).t('days')}'),
        const SizedBox(width: 10), const Icon(Icons.more_vert),
      ]),
      onTap: () => context.go('/event/${event.externalId}'),
    );
    return Draggable<MoviaEvent>(data: event, feedback: Material(elevation: 8, borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 420, child: row)), childWhenDragging: Opacity(opacity: .35, child: row),
      child: GestureDetector(onSecondaryTapDown: (d) => _contextMenu(context, ref, d.globalPosition), child: row));
  }
  Future<void> _contextMenu(BuildContext context, WidgetRef ref, Offset at) async {
    final action = await showMenu<String>(context: context, position: RelativeRect.fromLTRB(at.dx, at.dy, at.dx, at.dy), items: [
      PopupMenuItem(value:'edit', child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(s(context).t('edit')))),
      PopupMenuItem(value:'archive', child: ListTile(leading: Icon(archived ? Icons.restore : Icons.inventory_2_outlined), title: Text(s(context).t(archived ? 'restore' : 'archive')))),
      PopupMenuItem(value:'delete', child: ListTile(leading: const Icon(Icons.delete_outline), title: Text(s(context).t('delete')))),
    ]);
    if (!context.mounted) return;
    if (action == 'edit') showEventEditor(context, event: event);
    if (action == 'archive') ref.read(eventsProvider.notifier).archive(event, !archived);
    if (action == 'delete') ref.read(eventsProvider.notifier).delete(event.externalId);
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.event, required this.size}); final MoviaEvent event; final double size;
  @override Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(color: Color(event.colorArgb).withValues(alpha:.12), borderRadius: BorderRadius.circular(13)),
    child: Icon(eventIcon(event.icon), color: Color(event.colorArgb), size: size * .48));
}

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({super.key, required this.events}); final List<MoviaEvent> events;
  @override State<CalendarPanel> createState() => _CalendarPanelState();
}
class _CalendarPanelState extends State<CalendarPanel> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  @override Widget build(BuildContext context) {
    final firstOffset = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateTime(month.year, month.month + 1, 0).day;
    return Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(children: [
      Row(children: [
        Expanded(child: Text(DateFormat.yMMMM().format(month), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 18),
      GridView.count(shrinkWrap: true, crossAxisCount: 7, childAspectRatio: 1.05, physics: const NeverScrollableScrollPhysics(),
        children: [
          ...['S','M','T','W','T','F','S'].map((d) => Center(child: Text(d, style: Theme.of(context).textTheme.labelMedium))),
          ...List.generate(firstOffset, (_) => const SizedBox()),
          ...List.generate(days, (i) {
            final day = i + 1;
            final matches = widget.events.where((e) { final l=e.targetInstant.toLocal(); return l.year==month.year&&l.month==month.month&&l.day==day; }).toList();
            return DragTarget<MoviaEvent>(onAcceptWithDetails: (_) {},
              builder: (_, candidate, rejected) => Container(margin: const EdgeInsets.all(3), decoration: BoxDecoration(
                color: candidate.isNotEmpty ? Theme.of(context).colorScheme.primaryContainer : null, borderRadius: BorderRadius.circular(9)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$day'), if(matches.isNotEmpty) Container(width: 5,height: 5,margin: const EdgeInsets.only(top:4),
                    decoration: BoxDecoration(color: Color(matches.first.colorArgb), shape: BoxShape.circle)),
                ])));
          }),
        ]),
      const Spacer(),
      Row(children: [const Icon(Icons.drag_indicator, size: 18), const SizedBox(width: 6),
        Expanded(child: Text('Drag events onto dates', style: Theme.of(context).textTheme.bodySmall))]),
    ])));
  }
}

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value?.where((e)=>!e.archived).toList() ?? [];
    return Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children:[Expanded(child:Text(s(context).t('calendar'),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700))),
        FilledButton.icon(onPressed:()=>showEventEditor(context),icon:const Icon(Icons.add),label:Text(s(context).t('add')))]),
      const SizedBox(height:24), Expanded(child: Row(children:[
        Expanded(child:CalendarPanel(events:events)), const SizedBox(width:20),
        SizedBox(width:420,child:_EventPanel(events:events)),
      ])),
    ]));
  }
}

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider).value?.where((e)=>e.archived).toList() ?? [];
    return Padding(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(s(context).t('archive'),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700)),
      const SizedBox(height:24), Expanded(child:Card(child:events.isEmpty?Center(child:Text(s(context).t('noArchived'))):
        ListView.separated(padding:const EdgeInsets.all(18),itemCount:events.length,separatorBuilder:(_,_)=>const Divider(),itemBuilder:(_,i)=>EventTile(event:events[i],archived:true)))),
    ]));
  }
}

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key, required this.id}); final String id;
  @override Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventsProvider).value?.where((e)=>e.externalId==id).firstOrNull;
    if(event==null)return const Center(child:CircularProgressIndicator());
    return Padding(padding:const EdgeInsets.all(28),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      IconButton(onPressed:()=>context.pop(),icon:const Icon(Icons.arrow_back)),
      const SizedBox(height:14), Card(child:Padding(padding:const EdgeInsets.all(32),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[_IconBox(event:event,size:72),const SizedBox(width:20),Expanded(child:Text(event.title,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700))),
          OutlinedButton.icon(onPressed:()=>showEventEditor(context,event:event),icon:const Icon(Icons.edit_outlined),label:Text(s(context).t('edit')))]),
        const SizedBox(height:28), Text(DateFormat.yMMMMEEEEd().add_jm().format(event.targetInstant.toLocal()),style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:10), Text(event.description.isEmpty?'—':event.description),
        const SizedBox(height:28), CountdownPanel(event:event),
        const SizedBox(height:22), Row(children:[
          OutlinedButton.icon(onPressed:(){ref.read(eventsProvider.notifier).archive(event,!event.archived);context.go('/archive');},icon:Icon(event.archived?Icons.restore:Icons.inventory_2_outlined),label:Text(s(context).t(event.archived?'restore':'archive'))),
          const SizedBox(width:12), TextButton.icon(onPressed:()=>_confirmDelete(context,ref,event),icon:const Icon(Icons.delete_outline),label:Text(s(context).t('delete'))),
        ]),
      ]))),
    ]));
  }
}
Future<void> _confirmDelete(BuildContext context,WidgetRef ref,MoviaEvent event) async {
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(s(c).t('delete')),content:Text(s(c).t('confirmDelete')),actions:[
    TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(s(c).t('cancel'))),FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(s(c).t('delete')))]));
  if(ok==true){await ref.read(eventsProvider.notifier).delete(event.externalId);if(context.mounted)context.go('/dashboard');}
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){
    final settings=ref.watch(settingsProvider).value??const SettingsState();
    return ListView(padding:const EdgeInsets.all(28),children:[
      Text(s(context).t('settings'),style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700)),
      const SizedBox(height:24),Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s(context).t('appearance'),style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
        SegmentedButton<AppThemeMode>(segments:[
          ButtonSegment(value:AppThemeMode.system,label:Text(s(context).t('system')),icon:const Icon(Icons.brightness_auto)),
          ButtonSegment(value:AppThemeMode.light,label:Text(s(context).t('light')),icon:const Icon(Icons.light_mode_outlined)),
          ButtonSegment(value:AppThemeMode.dark,label:Text(s(context).t('dark')),icon:const Icon(Icons.dark_mode_outlined)),
        ],selected:{settings.theme},onSelectionChanged:(v)=>ref.read(settingsProvider.notifier).setTheme(v.first)),
        const SizedBox(height:28),Text(s(context).t('language'),style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),
        SegmentedButton<String>(segments:const [
          ButtonSegment(value:'system',label:Text('System')),ButtonSegment(value:'en',label:Text('English')),ButtonSegment(value:'ar',label:Text('العربية')),
        ],selected:{settings.language},onSelectionChanged:(v)=>ref.read(settingsProvider.notifier).setLanguage(v.first)),
      ]))),
      const SizedBox(height:20),Card(child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(s(context).t('data'),style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:8),
        const Text('Android-compatible schema v1 • UTF-8 JSON'),const SizedBox(height:18),
        Row(children:[FilledButton.tonalIcon(onPressed:()=>_import(context,ref),icon:const Icon(Icons.file_open_outlined),label:Text(s(context).t('import'))),
          const SizedBox(width:12),OutlinedButton.icon(onPressed:()=>_export(context,ref,settings),icon:const Icon(Icons.save_alt),label:Text(s(context).t('export')))]),
      ]))),
    ]);
  }
  Future<void> _export(BuildContext context,WidgetRef ref,SettingsState settings)async{
    final path=await getSaveLocation(suggestedName:'movia-export-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.json',acceptedTypeGroups:[const XTypeGroup(label:'JSON',extensions:['json'])]);
    if(path==null)return;
    final json=await ref.read(repositoryProvider).exportJson(settings.theme.name,settings.language);
    await File(path.path).writeAsString(json);
    if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s(context).t('exported'))));
  }
  Future<void> _import(BuildContext context,WidgetRef ref)async{
    try{
      final file=await openFile(acceptedTypeGroups:[const XTypeGroup(label:'JSON',extensions:['json'])]);if(file==null)return;
      final events=await ref.read(repositoryProvider).parseImport(File(file.path));if(!context.mounted)return;
      final replace=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:Text(s(c).t('preview')),content:Text('${events.length} ${s(c).t('events')}'),actions:[
        TextButton(onPressed:()=>Navigator.pop(c),child:Text(s(c).t('cancel'))),
        OutlinedButton(onPressed:()=>Navigator.pop(c,false),child:Text(s(c).t('merge'))),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(s(c).t('replace')))]));
      if(replace==null)return;await ref.read(repositoryProvider).applyImport(events,replace:replace);await ref.read(eventsProvider.notifier).reload();
      if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s(context).t('imported'))));
    }catch(_){if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s(context).t('invalid'))));}
  }
}

Future<void> showEventEditor(BuildContext context,{MoviaEvent? event})async{
  await showDialog(context:context,builder:(_)=>EventEditor(event:event));
}
class EventEditor extends ConsumerStatefulWidget {
  const EventEditor({super.key,this.event});final MoviaEvent? event;
  @override ConsumerState<EventEditor> createState()=>_EventEditorState();
}
class _EventEditorState extends ConsumerState<EventEditor>{
  late final TextEditingController title,description;late DateTime date;late TimeOfDay time;String icon='personal';
  @override void initState(){super.initState();final e=widget.event;title=TextEditingController(text:e?.title);description=TextEditingController(text:e?.description);final d=e?.targetInstant.toLocal()??DateTime.now().add(const Duration(days:7));date=d;time=TimeOfDay.fromDateTime(d);icon=e?.icon??'personal';}
  @override void dispose(){title.dispose();description.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text(s(context).t(widget.event==null?'add':'edit')),content:SizedBox(width:520,child:SingleChildScrollView(child:Column(children:[
    TextField(controller:title,autofocus:true,decoration:InputDecoration(labelText:s(context).t('title'))),const SizedBox(height:14),
    TextField(controller:description,maxLines:3,decoration:InputDecoration(labelText:s(context).t('description'))),const SizedBox(height:14),
    Row(children:[Expanded(child:OutlinedButton.icon(onPressed:()async{final v=await showDatePicker(context:context,firstDate:DateTime.now().subtract(const Duration(days:3650)),lastDate:DateTime.now().add(const Duration(days:36500)),initialDate:date);if(v!=null)setState(()=>date=v);},icon:const Icon(Icons.calendar_today),label:Text(DateFormat.yMMMd().format(date)))),
      const SizedBox(width:12),Expanded(child:OutlinedButton.icon(onPressed:()async{final v=await showTimePicker(context:context,initialTime:time);if(v!=null)setState(()=>time=v);},icon:const Icon(Icons.schedule),label:Text(time.format(context))))]),
    const SizedBox(height:14),DropdownMenu<String>(width:520,initialSelection:icon,label:Text(s(context).t('category')),onSelected:(v){if(v!=null)setState(()=>icon=v);},dropdownMenuEntries:['personal','work','travel','health','other'].map((v)=>DropdownMenuEntry(value:v,label:s(context).t(v),leadingIcon:Icon(eventIcon(v)))).toList()),
  ]))),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:Text(s(context).t('cancel'))),FilledButton(onPressed:_save,child:Text(s(context).t('save')))]);
  Future<void> _save()async{if(title.text.trim().isEmpty)return;final target=DateTime(date.year,date.month,date.day,time.hour,time.minute);final colors={'personal':0xFFFF6655,'work':0xFF4F46E5,'travel':0xFF6366F1,'health':0xFFF5A900,'other':0xFF2CB1BC};final e=MoviaEvent(externalId:widget.event?.externalId??const Uuid().v4(),title:title.text.trim(),description:description.text.trim(),targetInstant:target,timeZone:widget.event?.timeZone??'Asia/Dubai',colorArgb:colors[icon]!,icon:icon,archived:widget.event?.archived??false);await ref.read(eventsProvider.notifier).save(e);if(mounted)Navigator.pop(context);}
}
