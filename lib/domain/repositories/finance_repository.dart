import '../../data/models/transaction_item.dart';
import '../../data/models/monthly_summary.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/installment.dart';
import '../../data/models/savings_confirmation.dart';
import '../../data/models/bank_connection.dart';
import '../../data/models/payment_method_totals.dart';

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
  Future<void> addExpenseCategory(ExpenseCategory category);
  Future<void> updateExpenseCategory(ExpenseCategory category);
  Future<void> deleteExpenseCategory(int id);
  Future<bool> expenseCategoryKeyExists(String key);

  Future<List<Installment>> getInstallments();
  Future<void> addInstallment(Installment installment);
  Future<void> updateInstallment(Installment installment);
  Future<void> deleteInstallment(int id);

  Future<SavingsConfirmation?> getSavingsConfirmation(int year, int month);
  Future<void> saveSavingsConfirmation(SavingsConfirmation confirmation);
  Future<List<SavingsConfirmation>> getAllSavingsConfirmations();

  Future<List<BankConnection>> getBankConnections();
  Future<void> addBankConnection(BankConnection connection);
  Future<void> deleteBankConnection(int id);
  Future<Map<int, PaymentMethodTotals>> getPaymentMethodTotals();
  Future<Map<String, Map<int, PaymentMethodTotals>>>
      getMonthlyPaymentMethodTotals();
}
