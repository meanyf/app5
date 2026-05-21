// lib/map/activity.dart

class MediaItem {
  final String url;
  final String type; // "photo" | "video"

  const MediaItem({required this.url, required this.type});

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      MediaItem(url: json['url'] as String, type: json['type'] as String);

  Map<String, dynamic> toJson() => {'url': url, 'type': type};
}

class Activity {
  final String id;
  final String type;
  final String creatorId; // новое
  final String authorName; // новое
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime expiresAt;
  final int? maxParticipants;
  final List<MediaItem> media;

  const Activity({
    required this.id,
    required this.type,
    required this.creatorId, // новое
    this.authorName = '', // новое
    required this.title,
    this.description,
    this.maxParticipants,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.expiresAt,
    this.media = const [],
  });

  Activity copyWith({String? authorName}) => Activity(
    id: id,
    type: type,
    creatorId: creatorId,
    authorName: authorName ?? this.authorName,
    title: title,
    description: description,
    latitude: latitude,
    longitude: longitude,
    startsAt: startsAt,
    expiresAt: expiresAt,
    maxParticipants: maxParticipants,
    media: media,
  );

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    type: json['type'] as String,
    creatorId: json['creator_id'] as String, // новое
    title: json['title'] as String,
    description: json['description'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    startsAt: DateTime.parse(json['starts_at'] as String),
    expiresAt: DateTime.parse(json['expires_at'] as String),
    maxParticipants: json['max_participants'] as int?,
    media: (json['media'] as List<dynamic>? ?? [])
        .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
