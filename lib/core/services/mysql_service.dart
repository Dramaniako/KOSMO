import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

class MySqlService {
  MySQLConnection? _activeConn;
  Timer? _keepAliveTimer;
  Future<void> _lock = Future.value();

  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  /// Sequentializes all connection attempts and keeps connection alive for 5 seconds
  /// to prevent redundant handshake pings.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    final completer = Completer<T>();
    
    _lock = _lock.then((_) async {
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

        final result = await action(_activeConn!).timeout(const Duration(seconds: 15));
        completer.complete(result);
      } catch (e, stack) {
        // Clear broken connection
        _activeConn = null;
        completer.completeError(e, stack);
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
      }
    }).catchError((_) {
      // Prevent failure of one query from blocking subsequent queries in the chain
    });

    return completer.future;
  }
}

final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});
