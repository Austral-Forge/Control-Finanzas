import '../../data/models/transaction_item.dart';
import '../../data/models/monthly_summary.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';

abstract class FinanceRepository {
  Future<List<MonthlySummary>> getMonthlySummaries();
  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month);
  Future<void> addTransaction(TransactionItem item);
  Future<void> updateTransaction(TransactionItem item);
  Future<void> deleteTransaction(int id);

  Future<List<IncomeSource>> getIncomeSources();
  Future<void> addIncomeSource(IncomeSource source);
  Future<void> deleteIncomeSource(int id);

  Future<List<PaymentMethod>> getPaymentMethods();
  Future<void> addPaymentMethod(PaymentMethod method);
  Future<void> deletePaymentMethod(int id);

  Future<List<ExpenseCategory>> getExpenseCategories();
}
