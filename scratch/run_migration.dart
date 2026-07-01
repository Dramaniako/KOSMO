import 'dart:io';
import 'package:mysql_client_plus/mysql_client_plus.dart';

Future<void> addColumnIfNotExists(
  MySQLConnection conn,
  String tableName,
  String columnName,
  String definition,
) async {
  final query =
      "SELECT COUNT(*) FROM information_schema.columns "
      "WHERE table_schema = DATABASE() "
      "AND table_name = '$tableName' "
      "AND column_name = '$columnName'";
  final result = await conn.execute(query);
  final count = int.parse(result.rows.first.colAt(0) ?? '0');
  if (count == 0) {
    print("Adding column $columnName to $tableName...");
    await conn.execute("ALTER TABLE `$tableName` ADD COLUMN `$columnName` $definition");
  } else {
    print("Column $columnName already exists in $tableName.");
  }
}

void main() async {
  print('Starting database migration for sharing...');

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
    // 1. Programmatically check & add columns to existing tables
    await addColumnIfNotExists(conn, 'users', 'id_int', 'INT AUTO_INCREMENT UNIQUE');
    await addColumnIfNotExists(conn, 'users', 'is_verified', 'TINYINT(1) DEFAULT 0');
    await addColumnIfNotExists(conn, 'users', 'age', 'INT DEFAULT NULL');
    await addColumnIfNotExists(conn, 'users', 'gender', 'VARCHAR(20) DEFAULT NULL');
    await addColumnIfNotExists(conn, 'users', 'address', 'TEXT DEFAULT NULL');

    await addColumnIfNotExists(conn, 'properties', 'id_int', 'INT AUTO_INCREMENT UNIQUE');
    await addColumnIfNotExists(conn, 'properties', 'owner_id_int', 'INT DEFAULT NULL');

    await addColumnIfNotExists(conn, 'withdrawals', 'id_int', 'INT AUTO_INCREMENT UNIQUE');
    await addColumnIfNotExists(conn, 'withdrawals', 'landlord_id_int', 'INT DEFAULT NULL');

    await addColumnIfNotExists(conn, 'reviews', 'id_int', 'INT AUTO_INCREMENT UNIQUE');
    await addColumnIfNotExists(conn, 'reviews', 'property_id_int', 'INT DEFAULT NULL');
    await addColumnIfNotExists(conn, 'reviews', 'user_id_int', 'INT DEFAULT NULL');

    // 1b. Ensure price column in properties table has a default of 0
    print("Setting default value 0 for properties.price...");
    await conn.execute("ALTER TABLE properties MODIFY price INT NOT NULL DEFAULT 0");

    // 2. Read and run script for triggers, tables and seeds
    final migrationFile = File('scratch/migrate_db.sql');
    if (!migrationFile.existsSync()) {
      print('Error: scratch/migrate_db.sql not found.');
      exit(1);
    }

    final sqlContent = migrationFile.readAsStringSync();
    
    final statements = <String>[];
    final lines = sqlContent.split('\n');
    var currentStatement = '';
    var inTrigger = false;

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('--') || trimmed.isEmpty) {
        continue;
      }

      currentStatement += '$line\n';

      if (trimmed.toLowerCase().startsWith('create trigger')) {
        inTrigger = true;
      }

      if (inTrigger) {
        if (trimmed.toLowerCase() == 'end;') {
          statements.add(currentStatement.trim());
          currentStatement = '';
          inTrigger = false;
        }
      } else {
        if (trimmed.endsWith(';')) {
          statements.add(currentStatement.trim());
          currentStatement = '';
        }
      }
    }

    if (currentStatement.trim().isNotEmpty) {
      statements.add(currentStatement.trim());
    }

    print('Found ${statements.length} SQL statements to execute from script.');

    for (var i = 0; i < statements.length; i++) {
      var stmt = statements[i];
      if (stmt.endsWith(';')) {
        stmt = stmt.substring(0, stmt.length - 1);
      }

      print('Executing script statement #${i + 1}...');
      try {
        await conn.execute(stmt);
      } catch (e) {
        print('Error executing statement #${i + 1}:\n$stmt\nError: $e');
        rethrow;
      }
    }

    print('Database migration completed successfully!');
  } catch (e) {
    print('Failed to execute migration: $e');
  } finally {
    await conn.close();
    print('Connection closed.');
  }
}
