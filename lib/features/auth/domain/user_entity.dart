class UserEntity {
  final String name;
  final String email;
  final bool isVerified;

  const UserEntity({
    required this.name,
    required this.email,
    this.isVerified = false,
  });

  UserEntity copyWith({
    String? name,
    String? email,
    bool? isVerified,
  }) {
    return UserEntity(
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
