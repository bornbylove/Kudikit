class UserProfile {
  final String? userId;
  final String name;
  final String email;

  UserProfile({
    this.userId,
    required this.name,
    required this.email,
  });

  bool get isAuthenticated => userId != null && userId!.isNotEmpty;

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}
