class UserEntity {
  final int? id;
  final String name;
  final String email;
  final bool isVerified;
  final String role;
  final int? age;
  final String? phoneNumber;
  final String? gender;
  final String? address;

  const UserEntity({
    this.id,
    required this.name,
    required this.email,
    this.isVerified = false,
    this.role = 'tenant',
    this.age,
    this.phoneNumber,
    this.gender,
    this.address,
  });

  UserEntity copyWith({
    int? id,
    String? name,
    String? email,
    bool? isVerified,
    String? role,
    int? age,
    String? phoneNumber,
    String? gender,
    String? address,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      role: role ?? this.role,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      address: address ?? this.address,
    );
  }
}
