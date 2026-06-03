class UserProfile {
  final String id;
  final String phone;
  final String? name;
  final String? avatarUrl;
  final String? description;

  const UserProfile({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
    this.description,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    description: json['description'] as String?,
  );
}
