import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

import 'dart:async';

class MySqlService {
  Future<void> _lock = Future.value();

  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  /// Sequentializes all connection attempts to prevent exceeding the 5-connection Clever Cloud limit.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    final completer = Completer<T>();
    
    _lock = _lock.then((_) async {
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
        final result = await action(conn).timeout(const Duration(seconds: 15));
        completer.complete(result);
      } catch (e, stack) {
        completer.completeError(e, stack);
      } finally {
        if (conn != null) {
          try {
            await conn.close();
          } catch (_) {}
        }
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
