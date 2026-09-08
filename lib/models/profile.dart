class Profile {
  final String id;
  final String name;
  final String email;
  final String? profilePhoto;
  final String role;
  final bool isAdmin;
  final double totalProgress;
  final bool subscriptionActive;

  const Profile({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    required this.role,
    required this.isAdmin,
    required this.totalProgress,
    required this.subscriptionActive,
  });

  bool get isStaff => role == 'admin' || role == 'owner' || isAdmin;
  bool get isOwner => role == 'owner';

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: '${map['id'] ?? ''}',
      name: '${map['name'] ?? ''}',
      email: '${map['email'] ?? ''}',
      profilePhoto: map['profile_photo']?.toString(),
      role: '${map['role'] ?? 'student'}',
      isAdmin: map['is_admin'] == true,
      totalProgress: (map['total_progress'] as num?)?.toDouble() ?? 0,
      subscriptionActive: map['subscription_active'] == true,
    );
  }
}
