import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

class MySqlService {
  bool _isLocked = false;
  final List<Completer<void>> _queue = [];

  /// Locks execution to serialize connection usage
  Future<void> _acquireLock() async {
    if (!_isLocked) {
      _isLocked = true;
      return;
    }
    final completer = Completer<void>();
    _queue.add(completer);
    await completer.future;
  }

  /// Releases the lock and lets the next query run
  void _releaseLock() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      next.complete();
    } else {
      _isLocked = false;
    }
  }

  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  /// Sequentializes all connection attempts using a clean Mutex lock.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    await _acquireLock();

    MySQLConnection? conn;
    try {
      conn = await MySQLConnection.createConnection(
        host: DbCredentials.host,
        port: DbCredentials.port,
        userName: DbCredentials.user,
        password: DbCredentials.password,
        databaseName: DbCredentials.database,
        secure: false,
      ).timeout(const Duration(seconds: 5));
      
      await conn.connect().timeout(const Duration(seconds: 5));
      return await action(conn).timeout(const Duration(seconds: 15));
    } finally {
      if (conn != null) {
        try {
          await conn.close();
        } catch (_) {}
      }
      _releaseLock();
    }
  }
}

final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});
