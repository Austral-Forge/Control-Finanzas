import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/monthly_summary.dart';
import 'package:mis_finanzas/data/models/transaction_item.dart';
import 'package:mis_finanzas/domain/repositories/finance_repository.dart';
import 'package:mis_finanzas/main.dart';

class FakeFinanceRepository implements FinanceRepository {
  @override
  Future<List<MonthlySummary>> getMonthlySummaries() async {
    return [
      MonthlySummary(
        year: 2026,
        month: 5,
        totalIncome: 1000,
        totalCost: 500,
      )
    ];
  }

  @override
  Future<List<TransactionItem>> getTransactionsForMonth(int year, int month) async {
    return [];
  }

  @override
  Future<void> addTransaction(TransactionItem item) async {}

  @override
  Future<void> deleteTransaction(int id) async {}
}

void main() {
  testWidgets('App starts and displays title', (WidgetTester tester) async {
    final fakeRepo = FakeFinanceRepository();
    // Instanciar MyApp con la firma correcta (FinanceRepositoryImpl es subtipo de FinanceRepository)
    // Para simplificar el test usamos un cast dinámico o usamos la clase base en MyApp.
    await tester.pumpWidget(MyApp(financeRepository: fakeRepo as dynamic));

    // Esperar a que terminen las tareas asíncronas y animaciones
    await tester.pumpAndSettle();

    // Verificar que se muestre el título principal de la aplicación
    expect(find.text('Mis Finanzas 2026'), findsOneWidget);
  });
}
