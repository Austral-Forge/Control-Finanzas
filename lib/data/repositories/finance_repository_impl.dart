import '../../domain/repositories/finance_repository.dart';
import '../database/db_helper.dart';
import '../models/transaction_item.dart';
import '../models/monthly_summary.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  @override
  Future<List<MonthlySummary>> getMonthlySummaries() {
    return _dbHelper.getMonthlySummaries();
  }

  @override
  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) {
    return _dbHelper.getTransactionsForMonth(year, month);
  }

  @override
  Future<void> addTransaction(TransactionItem item) async {
    await _dbHelper.insertTransaction(item);
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteTransaction(id);
  }
}
