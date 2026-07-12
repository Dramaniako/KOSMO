import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

class MySqlService {
  MySQLConnection? _activeConn;
  Timer? _keepAliveTimer;
  
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
  /// Sequentializes all connection attempts and keeps connection alive for 5 seconds
  /// to prevent redundant handshake pings.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    await _acquireLock();

    // Cancel keep-alive timer if active
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;

    try {
      // Reuse or create connection
      if (_activeConn == null || !_activeConn!.connected) {
        _activeConn = await MySQLConnection.createConnection(
          host: DbCredentials.host,
          port: DbCredentials.port,
          userName: DbCredentials.user,
          password: DbCredentials.password,
          databaseName: DbCredentials.database,
          secure: false,
        ).timeout(const Duration(seconds: 5));
        
        await _activeConn!.connect().timeout(const Duration(seconds: 5));
      }

      return await action(_activeConn!).timeout(const Duration(seconds: 15));
    } catch (e) {
      // Clear broken connection
      _activeConn = null;
      rethrow;
    } finally {
      // Start keep-alive timer to close connection after 5 seconds of inactivity
      _keepAliveTimer = Timer(const Duration(seconds: 5), () async {
        if (_activeConn != null) {
          try {
            await _activeConn!.close();
          } catch (_) {}
          _activeConn = null;
        }
      });

      _releaseLock();
    }
  }
}

final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});
