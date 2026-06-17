import '../../data/models/transaction_item.dart';
import '../../data/models/monthly_summary.dart';

abstract class FinanceRepository {
  Future<List<MonthlySummary>> getMonthlySummaries();
  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month);
  Future<void> addTransaction(TransactionItem item);
  Future<void> deleteTransaction(int id);
}
