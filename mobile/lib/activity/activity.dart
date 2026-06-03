// lib/map/activity.dart

import '../core/media_service.dart';

class Activity {
  final String id;
  final String type;
  final String creatorId; // новое
  final String authorName; // новое
  final String? address; // 1. поле
  final String? authorAvatarUrl;
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
    this.address, // 2. конструктор
    this.authorAvatarUrl,
    required this.title,
    this.description,
    this.maxParticipants,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.expiresAt,
    this.media = const [],
  });

  Activity copyWith({String? authorName, String? authorAvatarUrl}) => Activity(
    id: id,
    type: type,
    creatorId: creatorId,
    authorName: authorName ?? this.authorName,
    authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
    address: address ?? this.address, // 3. copyWith
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
    address: json['address'] as String?, // 4. fromJson
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
