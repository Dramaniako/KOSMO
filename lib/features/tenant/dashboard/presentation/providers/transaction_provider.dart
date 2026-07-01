import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/mysql_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../landlord/dashboard/presentation/providers/landlord_provider.dart';
import '../../../../tenant/search/presentation/providers/search_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return TransactionRepository(mysqlService);
});

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;
    if (userId == null) return [];
    return repository.getTransactions(userId);
  }

  Future<void> addTransaction(TransactionModel transaction, [int? userId, int? roomId]) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.saveTransaction(transaction, userId, roomId);
      ref.invalidateSelf();
      
      // Invalidate landlord stats and search results reactively on success
      ref.invalidate(landlordProvider);
      ref.invalidate(landlordTenantsProvider);
      ref.invalidate(landlordTransactionsProvider);
      ref.invalidate(landlordReviewsProvider);
      ref.invalidate(searchProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> payArrears(String invoiceNumber) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(transactionRepositoryProvider);
      await repository.payArrearsTransaction(invoiceNumber);
      ref.invalidateSelf();
      
      // Invalidate landlord stats reactively on success
      ref.invalidate(landlordProvider);
      ref.invalidate(landlordTenantsProvider);
      ref.invalidate(landlordTransactionsProvider);
      ref.invalidate(landlordReviewsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionProvider = AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  TransactionNotifier.new,
);

class ActiveRental {
  final int id;
  final int propertyId;
  final String propertyTitle;
  final double price;
  final String roomNumber;
  final String description;
  final String imageUrl;
  final String address;
  final String landlordName;
  final String landlordEmail;
  final String? allInclusiveBills;

  const ActiveRental({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.price,
    required this.roomNumber,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.landlordName,
    required this.landlordEmail,
    this.allInclusiveBills,
  });
}

final activeRentalProvider = FutureProvider<ActiveRental?>((ref) async {
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;
  if (userId == null) return null;

  // Reactively rebuild whenever the transaction history updates (e.g. after new payment checkout)
  ref.watch(transactionProvider);

  final mysqlService = ref.watch(mysqlServiceProvider);
  return mysqlService.run((conn) async {
    final results = await conn.execute(
      "SELECT r.id as room_id, r.property_id, p.name as title, r.price, r.room_number, r.description, r.image_url, "
      "p.address, u.name as landlord_name, u.email as landlord_email, r.all_inclusive_bills "
      "FROM rooms r "
      "JOIN properties p ON r.property_id = p.id_int "
      "JOIN users u ON p.owner_id_int = u.id_int "
      "WHERE r.tenant_id = :userId "
      "LIMIT 1",
      {"userId": userId},
    );

    if (results.rows.isEmpty) {
      return null;
    }

    final row = results.rows.first;
    return ActiveRental(
      id: int.parse(row.colByName('room_id')!),
      propertyId: int.parse(row.colByName('property_id')!),
      propertyTitle: row.colByName('title') ?? '',
      price: double.tryParse(row.colByName('price') ?? '0') ?? 0.0,
      roomNumber: row.colByName('room_number') ?? '',
      description: row.colByName('description') ?? '',
      imageUrl: row.colByName('image_url') ?? '',
      address: row.colByName('address') ?? '',
      landlordName: row.colByName('landlord_name') ?? '',
      landlordEmail: row.colByName('landlord_email') ?? '',
      allInclusiveBills: row.colByName('all_inclusive_bills'),
    );
  });
});
