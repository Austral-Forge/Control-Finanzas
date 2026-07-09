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

  group('ProjectedMonth.series', () {
    test('genera una tarjeta por cada mes con cuotas pendientes de un prestamo largo', () {
      // Prestamo de la mama: junio a 16 meses, ya pagadas junio y julio.
      final loan = cuota(
        monthlyAmount: 50000, installmentCount: 16, paidCount: 2,
        startYear: 2026, startMonth: 6,
      );
      // El ultimo mes real con datos es julio (donde se pago la 2da cuota).
      final series = ProjectedMonth.series(
        lastYear: 2026, lastMonth: 7,
        carriedBalance: 300000,
        installments: [loan],
      );

      // Quedan 14 cuotas pendientes: agosto 2026 a septiembre 2027.
      expect(series.length, 14);
      expect(series.first.year, 2026);
      expect(series.first.month, 8);
      expect(series.last.year, 2027);
      expect(series.last.month, 9);
      for (final pm in series) {
        expect(pm.projectedExpenses, 50000);
      }
    });

    test('el saldo se arrastra de un mes proyectado al siguiente', () {
      final loan = cuota(
        monthlyAmount: 100000, installmentCount: 3, paidCount: 0,
        startYear: 2026, startMonth: 8,
      );
      final series = ProjectedMonth.series(
        lastYear: 2026, lastMonth: 7,
        carriedBalance: 250000,
        installments: [loan],
      );
      expect(series.length, 3);
      expect(series[0].carriedBalance, 250000);
      expect(series[0].projectedBalance, 150000);
      expect(series[1].carriedBalance, 150000);
      expect(series[1].projectedBalance, 50000);
      expect(series[2].carriedBalance, 50000);
      expect(series[2].projectedBalance, -50000);
    });

    test('sin cuotas pendientes devuelve un solo mes (el siguiente)', () {
      final series = ProjectedMonth.series(
        lastYear: 2026, lastMonth: 7,
        carriedBalance: 100000,
        installments: [],
      );
      expect(series.length, 1);
      expect(series.first.year, 2026);
      expect(series.first.month, 8);
    });

    test('solo el primer mes de la serie respeta savingsConfirmed', () {
      final loan = cuota(
        monthlyAmount: 10000, installmentCount: 2, paidCount: 0,
        startYear: 2026, startMonth: 8,
      );
      final series = ProjectedMonth.series(
        lastYear: 2026, lastMonth: 7,
        carriedBalance: 50000,
        installments: [loan],
        savingsConfirmed: false,
      );
      expect(series[0].savingsConfirmed, isFalse);
      expect(series[1].savingsConfirmed, isTrue);
    });
  });
}
