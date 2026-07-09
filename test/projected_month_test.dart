import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/installment.dart';
import 'package:mis_finanzas/data/models/projected_month.dart';

void main() {
  Installment cuota({
    double monthlyAmount = 30000,
    int installmentCount = 6,
    int paidCount = 0,
    int startYear = 2026,
    int startMonth = 4,
    String kind = Installment.kindPago,
  }) =>
      Installment(
        description: 'Cuota test',
        category: 'tarjeta_credito',
        monthlyAmount: monthlyAmount,
        installmentCount: installmentCount,
        paidCount: paidCount,
        startYear: startYear,
        startMonth: startMonth,
        kind: kind,
      );

  group('ProjectedMonth', () {
    test('sin cuotas, el balance es el saldo arrastrado', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 6,
        carriedBalance: 150000,
        installments: [],
      );
      expect(pm.year, 2026);
      expect(pm.month, 7);
      expect(pm.projectedExpenses, 0);
      expect(pm.projectedBalance, 150000);
      expect(pm.isDeficit, isFalse);
      expect(pm.hasInstallments, isFalse);
    });

    test('con cuotas pendientes, las resta del saldo', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 5,
        carriedBalance: 200000,
        installments: [
          cuota(monthlyAmount: 50000, startYear: 2026, startMonth: 4, installmentCount: 6, paidCount: 0),
          cuota(monthlyAmount: 30000, startYear: 2026, startMonth: 6, installmentCount: 3, paidCount: 0),
        ],
      );
      expect(pm.month, 6);
      expect(pm.projectedExpenses, 80000);
      expect(pm.projectedBalance, 120000);
    });

    test('cuotas ya pagadas no se proyectan', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 6,
        carriedBalance: 100000,
        installments: [
          cuota(monthlyAmount: 25000, startYear: 2026, startMonth: 1, installmentCount: 6, paidCount: 6),
        ],
      );
      expect(pm.hasInstallments, isFalse);
      expect(pm.projectedBalance, 100000);
    });

    test('saldo negativo genera deficit', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 3,
        carriedBalance: -50000,
        installments: [
          cuota(monthlyAmount: 20000, startYear: 2026, startMonth: 1, installmentCount: 12, paidCount: 0),
        ],
      );
      expect(pm.projectedBalance, -70000);
      expect(pm.isDeficit, isTrue);
    });

    test('cuota prestada suma al balance como ingreso proyectado', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 6,
        carriedBalance: 100000,
        installments: [
          cuota(monthlyAmount: 40000, startYear: 2026, startMonth: 5,
              installmentCount: 6, kind: Installment.kindPrestado),
          cuota(monthlyAmount: 25000, startYear: 2026, startMonth: 5,
              installmentCount: 6, kind: Installment.kindRecibido),
        ],
      );
      expect(pm.projectedIncomes, 40000);
      expect(pm.projectedExpenses, 25000);
      expect(pm.projectedBalance, 115000);
    });

    test('cruce de anio funciona correctamente', () {
      final pm = ProjectedMonth.next(
        lastYear: 2026, lastMonth: 12,
        carriedBalance: 80000,
        installments: [
          cuota(monthlyAmount: 15000, startYear: 2026, startMonth: 11, installmentCount: 4, paidCount: 0),
        ],
      );
      expect(pm.year, 2027);
      expect(pm.month, 1);
      expect(pm.projectedExpenses, 15000);
      expect(pm.projectedBalance, 65000);
    });
  });
}
