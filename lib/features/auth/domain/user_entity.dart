class UserEntity {
  final int? id;
  final String name;
  final String email;
  final bool isVerified;

  const UserEntity({
    this.id,
    required this.name,
    required this.email,
    this.isVerified = false,
  });

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    bool? isVerified,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
