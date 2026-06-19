import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/monthly_summary.dart';
import 'package:mis_finanzas/data/models/monthly_projection.dart';

void main() {
  MonthlySummary summary(int month, double income, double cost) =>
      MonthlySummary(year: 2026, month: month, totalIncome: income, totalCost: cost);

  group('MonthlyProjection', () {
    test('sin ahorro previo, el ingreso efectivo es el ingreso del mes', () {
      final p = MonthlyProjection(
        summary: summary(1, 800, 300),
        previousSavings: 0,
      );
      expect(p.carriedSavings, 0);
      expect(p.effectiveIncome, 800);
    });

    test('carriedSavings ignora un ahorro previo negativo', () {
      final p = MonthlyProjection(
        summary: summary(1, 1000, 500),
        previousSavings: -300,
      );
      expect(p.carriedSavings, 0);
      expect(p.hasCarriedSavings, isFalse);
      expect(p.effectiveIncome, 1000);
    });

    test('carriedSavings suma un ahorro previo positivo al ingreso', () {
      final p = MonthlyProjection(
        summary: summary(2, 1000, 400),
        previousSavings: 250,
      );
      expect(p.carriedSavings, 250);
      expect(p.effectiveIncome, 1250);
      expect(p.savingsPotential, 1250 - 400);
    });

    test('savingsRate usa solo el ingreso propio del mes', () {
      final p = MonthlyProjection(
        summary: summary(3, 1000, 750),
        previousSavings: 500,
      );
      expect(p.savingsRate, closeTo(0.25, 1e-9));
    });

    test('savingsRate es 0 cuando no hay ingreso', () {
      final p = MonthlyProjection(
        summary: summary(4, 0, 200),
        previousSavings: 0,
      );
      expect(p.savingsRate, 0);
    });

    test('fromChronological acumula el ahorro de meses anteriores', () {
      final summaries = [
        summary(1, 1000, 600), // balance +400
        summary(2, 1000, 900), // balance +100, previo 400
        summary(3, 1000, 1200), // balance -200, previo 500
      ];

      final projections = MonthlyProjection.fromChronological(summaries);

      expect(projections[0].previousSavings, 0);
      expect(projections[1].previousSavings, 400);
      expect(projections[2].previousSavings, 500);
    });
  });
}
