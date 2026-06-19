import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/installment.dart';

void main() {
  Installment make({
    int installmentCount = 12,
    int paidCount = 0,
    double monthlyAmount = 50000,
    int startYear = 2026,
    int startMonth = 1,
  }) =>
      Installment(
        description: 'Test',
        category: 'tarjeta_credito',
        monthlyAmount: monthlyAmount,
        installmentCount: installmentCount,
        paidCount: paidCount,
        startYear: startYear,
        startMonth: startMonth,
      );

  group('Installment getters', () {
    test('remainingCount y remainingBalance', () {
      final inst = make(installmentCount: 12, paidCount: 4, monthlyAmount: 10000);
      expect(inst.remainingCount, 8);
      expect(inst.remainingBalance, 80000);
      expect(inst.totalAmount, 120000);
    });

    test('isCompleted cuando se pagaron todas', () {
      final inst = make(installmentCount: 6, paidCount: 6);
      expect(inst.isCompleted, isTrue);
      expect(inst.remainingCount, 0);
      expect(inst.remainingBalance, 0);
    });
  });

  group('dueAmountForMonth', () {
    test('devuelve monto para cuota pendiente', () {
      final inst = make(
        startYear: 2026, startMonth: 3,
        installmentCount: 6, paidCount: 0, monthlyAmount: 25000,
      );
      expect(inst.dueAmountForMonth(2026, 3), 25000);
      expect(inst.dueAmountForMonth(2026, 5), 25000);
      expect(inst.dueAmountForMonth(2026, 8), 25000);
    });

    test('devuelve 0 para cuota ya pagada', () {
      final inst = make(
        startYear: 2026, startMonth: 1,
        installmentCount: 6, paidCount: 3, monthlyAmount: 10000,
      );
      expect(inst.dueAmountForMonth(2026, 1), 0);
      expect(inst.dueAmountForMonth(2026, 2), 0);
      expect(inst.dueAmountForMonth(2026, 3), 0);
      expect(inst.dueAmountForMonth(2026, 4), 10000);
    });

    test('devuelve 0 antes del inicio', () {
      final inst = make(startYear: 2026, startMonth: 6);
      expect(inst.dueAmountForMonth(2026, 5), 0);
      expect(inst.dueAmountForMonth(2025, 12), 0);
    });

    test('devuelve 0 despues de la ultima cuota', () {
      final inst = make(
        startYear: 2026, startMonth: 1, installmentCount: 3,
      );
      expect(inst.dueAmountForMonth(2026, 4), 0);
      expect(inst.dueAmountForMonth(2027, 1), 0);
    });

    test('funciona cruzando anios', () {
      final inst = make(
        startYear: 2026, startMonth: 11,
        installmentCount: 4, paidCount: 0, monthlyAmount: 5000,
      );
      expect(inst.dueAmountForMonth(2026, 11), 5000);
      expect(inst.dueAmountForMonth(2026, 12), 5000);
      expect(inst.dueAmountForMonth(2027, 1), 5000);
      expect(inst.dueAmountForMonth(2027, 2), 5000);
      expect(inst.dueAmountForMonth(2027, 3), 0);
    });
  });
}
