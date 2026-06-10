import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final storedHash = row.colByName('password_hash');
      final inputHash = _hashPassword(password);

      if (storedHash == inputHash) {
        return UserEntity(
          id: int.tryParse(row.colByName('id') ?? ''),
          name: row.colByName('name') ?? '',
          email: row.colByName('email') ?? '',
          isVerified: row.colByName('is_verified') == '1',
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
        'INSERT INTO users (name, email, password_hash, is_verified) '
        'VALUES (:name, :email, :password_hash, 0)',
        {
          'name': name,
          'email': email,
          'password_hash': passwordHash,
        },
      );

      if (result.affectedRows > BigInt.zero) {
        return UserEntity(
          id: result.lastInsertID.toInt(),
          name: name,
          email: email,
          isVerified: false,
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
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return AuthRepository(mysqlService);
});
