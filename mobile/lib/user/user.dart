class UserProfile {
  final String id;
  final String phone;
  final String? name;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.phone,
    this.name,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}
