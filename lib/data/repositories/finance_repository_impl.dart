import '../../domain/repositories/finance_repository.dart';
import '../database/db_helper.dart';
import '../models/transaction_item.dart';
import '../models/monthly_summary.dart';
import '../models/income_source.dart';
import '../models/payment_method.dart';
import '../models/expense_category.dart';

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

  @override
  Future<List<IncomeSource>> getIncomeSources() {
    return _dbHelper.getIncomeSources();
  }

  @override
  Future<void> addIncomeSource(IncomeSource source) async {
    await _dbHelper.insertIncomeSource(source);
  }

  @override
  Future<void> deleteIncomeSource(int id) async {
    await _dbHelper.deleteIncomeSource(id);
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods() {
    return _dbHelper.getPaymentMethods();
  }

  @override
  Future<void> addPaymentMethod(PaymentMethod method) async {
    await _dbHelper.insertPaymentMethod(method);
  }

  @override
  Future<void> deletePaymentMethod(int id) async {
    await _dbHelper.deletePaymentMethod(id);
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() {
    return _dbHelper.getExpenseCategories();
  }
}
