import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../../../core/services/mysql_service.dart';
import '../../domain/user_entity.dart';

class AuthRepository {
  final MySqlService _mysqlService;

  AuthRepository(this._mysqlService);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserEntity?> login(String email, String password) async {
    return _mysqlService.run((conn) async {
      final results = await conn.execute(
        'SELECT * FROM users WHERE email = :email',
        {'email': email},
      );
      if (results.rows.isEmpty) return null;

      final row = results.rows.first;
      final storedHash = row.colByName('password') ?? '';
      final inputHash = _hashPassword(password);

      bool isValid = false;
      if (storedHash.startsWith('\$2a\$') || 
          storedHash.startsWith('\$2b\$') || 
          storedHash.startsWith('\$2y\$')) {
        try {
          isValid = BCrypt.checkpw(password, storedHash);
        } catch (_) {
          isValid = false;
        }
      } else {
        isValid = (storedHash == inputHash || storedHash == password);
      }

      if (isValid) {
        return UserEntity(
          id: int.tryParse(row.colByName('id_int') ?? ''),
          name: row.colByName('name') ?? '',
          email: row.colByName('email') ?? '',
          isVerified: row.colByName('is_verified') == '1',
          role: row.colByName('role') ?? 'tenant',
          age: row.colByName('age') != null ? int.tryParse(row.colByName('age')!) : null,
          phoneNumber: row.colByName('phone'),
          gender: row.colByName('gender'),
          address: row.colByName('address'),
        );
      }
      return null;
    });
  }

  Future<UserEntity?> register(String name, String email, String password) async {
    return _mysqlService.run((conn) async {
      // 1. Check if email already exists
      final checkResults = await conn.execute(
        'SELECT * FROM users WHERE email = :email',
        {'email': email},
      );
      if (checkResults.rows.isNotEmpty) {
        throw Exception('Email sudah terdaftar.');
      }

      // 2. Hash password and insert
      final passwordHash = _hashPassword(password);
      final result = await conn.execute(
        "INSERT INTO users (name, email, password, is_verified, role) "
        "VALUES (:name, :email, :password, 0, 'tenant')",
        {
          'name': name,
          'email': email,
          'password': passwordHash,
        },
      );

      if (result.affectedRows > BigInt.zero) {
        return UserEntity(
          id: result.lastInsertID.toInt(),
          name: name,
          email: email,
          isVerified: false,
          role: 'tenant',
        );
      }
      return null;
    });
  }

  Future<bool> verifyUser(String email) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        'UPDATE users SET is_verified = 1 WHERE email = :email',
        {'email': email},
      );
      return result.affectedRows > BigInt.zero;
    });
  }

  Future<bool> updateProfile({
    required int id,
    required String name,
    required int age,
    required String phoneNumber,
    required String gender,
    required String address,
  }) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        'UPDATE users SET name = :name, age = :age, phone = :phone, '
        'gender = :gender, address = :address WHERE id_int = :id',
        {
          'id': id,
          'name': name,
          'age': age,
          'phone': phoneNumber,
          'gender': gender,
          'address': address,
        },
      );
      return result.affectedRows > BigInt.zero;
    });
  }

  Future<bool> upgradeRole(int id, String newRole) async {
    return _mysqlService.run((conn) async {
      final result = await conn.execute(
        'UPDATE users SET role = :role WHERE id_int = :id',
        {
          'id': id,
          'role': newRole,
        },
      );
      return result.affectedRows > BigInt.zero;
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return AuthRepository(mysqlService);
});
