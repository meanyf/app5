class Activity {
  final String id;
  final String type;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final DateTime startsAt;
  final DateTime expiresAt;
  final int? maxParticipants;


  const Activity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.maxParticipants,
    required this.latitude,
    required this.longitude,
    required this.startsAt,
    required this.expiresAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    startsAt: DateTime.parse(json['starts_at'] as String),
    expiresAt: DateTime.parse(json['expires_at'] as String),
    maxParticipants: json['max_participants'] as int?,
  );
}
