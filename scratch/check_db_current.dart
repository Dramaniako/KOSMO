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
  print('Connected to database.');

  try {
    print('\n=== USERS ===');
    final users = await conn.execute('SELECT id, id_int, name, email, role FROM users');
    for (var r in users.rows) {
      print('User: id_int=${r.colByName('id_int')}, id=${r.colByName('id')}, name=${r.colByName('name')}, email=${r.colByName('email')}, role=${r.colByName('role')}');
    }

    print('\n=== PROPERTIES ===');
    final props = await conn.execute('SELECT id, id_int, ownerId, owner_id_int, name FROM properties');
    for (var r in props.rows) {
      print('Prop: id_int=${r.colByName('id_int')}, id=${r.colByName('id')}, name=${r.colByName('name')}, owner_id_int=${r.colByName('owner_id_int')}, ownerId=${r.colByName('ownerId')}');
    }

    print('\n=== ROOMS WITH TENANTS ===');
    final rooms = await conn.execute('SELECT id, property_id, room_number, tenant_id FROM rooms WHERE tenant_id IS NOT NULL');
    for (var r in rooms.rows) {
      print('Room: id=${r.colByName('id')}, property_id=${r.colByName('property_id')}, room_number=${r.colByName('room_number')}, tenant_id=${r.colByName('tenant_id')}');
    }

    print('\n=== TRANSACTIONS ===');
    final txs = await conn.execute('SELECT id, invoice_number, amount, status, property_id, user_id, transaction_type FROM transactions');
    for (var r in txs.rows) {
      print('Tx: id=${r.colByName('id')}, invoice=${r.colByName('invoice_number')}, amount=${r.colByName('amount')}, status=${r.colByName('status')}, property_id=${r.colByName('property_id')}, user_id=${r.colByName('user_id')}, type=${r.colByName('transaction_type')}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await conn.close();
  }
}
