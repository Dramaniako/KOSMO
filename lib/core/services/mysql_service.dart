import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

class MySqlService {
  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
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
    }
  }
}

final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});
