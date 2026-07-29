class MoviaEvent {
  const MoviaEvent({
    required this.externalId, required this.title, required this.targetInstant,
    this.description = '', this.timeZone = 'Asia/Dubai', this.colorArgb = 0xFF4F46E5,
    this.icon = 'other', this.archived = false,
  });
  final String externalId, title, description, timeZone, icon;
  final DateTime targetInstant;
  final int colorArgb;
  final bool archived;
  MoviaEvent copyWith({String? title, String? description, DateTime? targetInstant,
    String? timeZone, int? colorArgb, String? icon, bool? archived}) => MoviaEvent(
      externalId: externalId, title: title ?? this.title, description: description ?? this.description,
      targetInstant: targetInstant ?? this.targetInstant, timeZone: timeZone ?? this.timeZone,
      colorArgb: colorArgb ?? this.colorArgb, icon: icon ?? this.icon, archived: archived ?? this.archived);
  Map<String, Object?> toDb() => {
    'external_id': externalId, 'title': title, 'description': description,
    'target_instant': targetInstant.toUtc().toIso8601String(), 'time_zone': timeZone,
    'color_argb': colorArgb, 'icon': icon, 'archived': archived ? 1 : 0,
  };
  Map<String, Object?> toJson() => {
    'externalId': externalId, 'title': title, 'description': description,
    'targetInstant': targetInstant.toUtc().toIso8601String(), 'timeZone': timeZone,
    'colorArgb': colorArgb, 'icon': icon, 'archived': archived,
  };
  factory MoviaEvent.fromMap(Map<String, Object?> m, {bool json = false}) => MoviaEvent(
    externalId: m[json ? 'externalId' : 'external_id'] as String,
    title: m['title'] as String, description: (m['description'] as String?) ?? '',
    targetInstant: DateTime.parse(m[json ? 'targetInstant' : 'target_instant'] as String),
    timeZone: (m[json ? 'timeZone' : 'time_zone'] as String?) ?? 'UTC',
    colorArgb: (m[json ? 'colorArgb' : 'color_argb'] as num).toInt(),
    icon: (m['icon'] as String?) ?? 'other',
    archived: json ? (m['archived'] as bool? ?? false) : (m['archived'] as int) == 1,
  );
}
