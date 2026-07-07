import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import '../config/db_credentials.dart';

class MySqlService {
  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    final conn = await MySQLConnection.createConnection(
      host: DbCredentials.host,
      port: DbCredentials.port,
      userName: DbCredentials.user,
      password: DbCredentials.password,
      databaseName: DbCredentials.database,
      secure: true,
    );
    await conn.connect();
    try {
      return await action(conn);
    } finally {
      await conn.close();
    }
  }
}

final mysqlServiceProvider = Provider<MySqlService>((ref) {
  return MySqlService();
});
