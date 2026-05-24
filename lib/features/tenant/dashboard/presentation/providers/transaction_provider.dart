import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../search/presentation/providers/search_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TransactionRepository(apiClient);
});

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final repository = ref.watch(transactionRepositoryProvider);
    return repository.getTransactions();
  }

  void addTransaction(TransactionModel transaction) {
    state.whenData((currentList) {
      state = AsyncValue.data([transaction, ...currentList]);
    });
  }
}

final transactionProvider = AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(
  TransactionNotifier.new,
);
