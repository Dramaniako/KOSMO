import 'package:mysql_client_plus/mysql_client_plus.dart';

void main() async {
  print('Connecting to database...');
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
    final tablesResult = await conn.execute('SHOW TABLES');
    final tables = <String>[];
    for (var row in tablesResult.rows) {
      tables.add(row.assoc().values.first!);
    }
    print('Tables: $tables');

    for (var table in tables) {
      print('\n--- Table: $table ---');
      final descResult = await conn.execute('DESCRIBE `$table`');
      for (var row in descResult.rows) {
        final field = row.colByName('Field');
        final type = row.colByName('Type');
        final nullVal = row.colByName('Null');
        final key = row.colByName('Key');
        final defVal = row.colByName('Default');
        print('  $field | $type | Null: $nullVal | Key: $key | Default: $defVal');
      }
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
