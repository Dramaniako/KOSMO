import 'package:mysql_client_plus/mysql_client_plus.dart';

void main() async {
  final conn = await MySQLConnection.createConnection(
    host: '127.0.0.1',
    port: 3306,
    userName: 'root',
    password: '12Bayu12',
    databaseName: 'kosmo',
  );

  await conn.connect();
  print('Connected.');

  try {
    final tables = ['users', 'properties', 'property_facilities', 'reviews', 'withdrawals'];
    for (var table in tables) {
      print('\n--- Data in Table: $table ---');
      final result = await conn.execute('SELECT * FROM `$table`');
      for (var row in result.rows) {
        print(row.assoc());
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
