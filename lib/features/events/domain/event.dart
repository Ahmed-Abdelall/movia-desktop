class MoviaEvent {
  const MoviaEvent({
    required this.externalId,
    required this.title,
    required this.targetInstant,
    this.description = '',
    this.timeZone = 'Asia/Dubai',
    this.colorArgb = 0xFF4F46E5,
    this.icon = 'other',
    this.archived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? targetInstant,
       updatedAt = updatedAt ?? createdAt ?? targetInstant;
  final String externalId, title, description, timeZone, icon;
  final DateTime targetInstant;
  final int colorArgb;
  final bool archived;
  final DateTime createdAt, updatedAt;
  MoviaEvent copyWith({
    String? title,
    String? description,
    DateTime? targetInstant,
    String? timeZone,
    int? colorArgb,
    String? icon,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MoviaEvent(
    externalId: externalId,
    title: title ?? this.title,
    description: description ?? this.description,
    targetInstant: targetInstant ?? this.targetInstant,
    timeZone: timeZone ?? this.timeZone,
    colorArgb: colorArgb ?? this.colorArgb,
    icon: icon ?? this.icon,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Map<String, Object?> toDb() => {
    'external_id': externalId,
    'title': title,
    'description': description,
    'target_instant': targetInstant.toUtc().toIso8601String(),
    'time_zone': timeZone,
    'color_argb': colorArgb,
    'icon': icon,
    'archived': archived ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
  Map<String, Object?> toJson() => {
    'externalId': externalId,
    'title': title,
    'description': description,
    'targetInstant': targetInstant.toUtc().toIso8601String(),
    'timeZone': timeZone,
    'colorArgb': colorArgb,
    'icon': icon,
    'archived': archived,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
  factory MoviaEvent.fromMap(
    Map<String, Object?> m, {
    bool json = false,
  }) => MoviaEvent(
    externalId: m[json ? 'externalId' : 'external_id'] as String,
    title: m['title'] as String,
    description: (m['description'] as String?) ?? '',
    targetInstant: DateTime.parse(
      m[json ? 'targetInstant' : 'target_instant'] as String,
    ),
    timeZone: (m[json ? 'timeZone' : 'time_zone'] as String?) ?? 'UTC',
    colorArgb: (m[json ? 'colorArgb' : 'color_argb'] as num).toInt(),
    icon: (m['icon'] as String?) ?? 'other',
    archived: json
        ? (m['archived'] as bool? ?? false)
        : (m['archived'] as int) == 1,
    createdAt:
        _date(m[json ? 'createdAt' : 'created_at']) ??
        DateTime.parse(m[json ? 'targetInstant' : 'target_instant'] as String),
    updatedAt:
        _date(m[json ? 'updatedAt' : 'updated_at']) ??
        _date(m[json ? 'createdAt' : 'created_at']) ??
        DateTime.parse(m[json ? 'targetInstant' : 'target_instant'] as String),
  );
}

DateTime? _date(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
