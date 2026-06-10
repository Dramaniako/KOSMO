import 'dart:io';
import 'package:mysql_client_plus/mysql_client_plus.dart';

void main() async {
  print('Starting database migration and seeding...');

  final conn = await MySQLConnection.createConnection(
    host: '127.0.0.1',
    port: 3306,
    userName: 'root',
    password: '12Bayu12',
    databaseName: 'kosmo',
  );

  await conn.connect();
  print('Connected to database.');

  try {
    final schemaFile = File('schema.sql');
    if (!schemaFile.existsSync()) {
      print('Error: schema.sql not found at ${schemaFile.absolute.path}');
      exit(1);
    }

    final schemaSql = schemaFile.readAsStringSync();
    
    // Split statements by semicolon. Be careful of semicolons in strings or comments.
    // Since our schema.sql is relatively simple, we can split by semicolon.
    // Let's filter out comments and parse queries correctly.
    final statements = <String>[];
    final lines = schemaSql.split('\n');
    var currentStatement = '';
    
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('--') || trimmed.isEmpty) {
        continue;
      }
      
      currentStatement += '$line\n';
      
      if (trimmed.endsWith(';')) {
        statements.add(currentStatement.trim());
        currentStatement = '';
      }
    }

    print('Found ${statements.length} SQL statements to execute.');

    for (var i = 0; i < statements.length; i++) {
      final stmt = statements[i];
      // Remove trailing semicolon for mysql_client execution if needed,
      // but mysql_client_plus can handle it. Let's strip the trailing semicolon just in case.
      var cleanStmt = stmt;
      if (cleanStmt.endsWith(';')) {
        cleanStmt = cleanStmt.substring(0, cleanStmt.length - 1);
      }
      
      try {
        await conn.execute(cleanStmt);
      } catch (e) {
        print('Error executing statement #$i:\n$stmt\nError: $e');
        rethrow;
      }
    }

    print('Migration and seeding completed successfully!');
  } catch (e) {
    print('Failed to reset database: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
