import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/monthly_summary.dart';
import 'package:mis_finanzas/data/models/transaction_item.dart';
import 'package:mis_finanzas/data/models/income_source.dart';
import 'package:mis_finanzas/data/models/payment_method.dart';
import 'package:mis_finanzas/data/models/expense_category.dart';
import 'package:mis_finanzas/domain/repositories/finance_repository.dart';

class FakeFinanceRepository implements FinanceRepository {
  @override
  Future<List<MonthlySummary>> getMonthlySummaries() async {
    return [
      MonthlySummary(year: 2026, month: 5, totalIncome: 1000, totalCost: 500)
    ];
  }

  @override
  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async => [];

  @override
  Future<void> addTransaction(TransactionItem item) async {}

  @override
  Future<void> updateTransaction(TransactionItem item) async {}

  @override
  Future<void> deleteTransaction(int id) async {}

  @override
  Future<List<IncomeSource>> getIncomeSources() async =>
      [IncomeSource(id: 1, name: 'Sueldo')];

  @override
  Future<void> addIncomeSource(IncomeSource source) async {}

  @override
  Future<void> deleteIncomeSource(int id) async {}

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async =>
      [PaymentMethod(id: 1, name: 'Efectivo')];

  @override
  Future<void> addPaymentMethod(PaymentMethod method) async {}

  @override
  Future<void> deletePaymentMethod(int id) async {}

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async => [];
}

void main() {
  testWidgets('FakeFinanceRepository implements all methods', (tester) async {
    final repo = FakeFinanceRepository();
    final summaries = await repo.getMonthlySummaries();
    expect(summaries.length, 1);
    expect(summaries.first.balance, 500);
  });
}
