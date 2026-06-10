import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';

class MySqlService {
  /// Safely runs a database query by connecting, executing the query,
  /// and automatically closing the connection.
  Future<T> run<T>(Future<T> Function(MySQLConnection conn) action) async {
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 3306,
      userName: 'root',
      password: '12Bayu12',
      databaseName: 'kosmo',
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
