class UserProfile {
  final String name;
  final String email;
  final String apiKey;

  UserProfile({
    required this.name,
    required this.email,
    required this.apiKey,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    String? apiKey,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
