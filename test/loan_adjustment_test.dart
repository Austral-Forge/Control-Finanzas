import 'package:flutter_test/flutter_test.dart';
import 'package:mis_finanzas/data/models/installment.dart';
import 'package:mis_finanzas/data/models/loan_adjustment.dart';

void main() {
  group('LoanAdjustment.forMonth', () {
    test('cuota "recibido" (me prestaron) se ve como egreso en el mes exacto', () {
      // Prestamo que hizo la mama: empezo en junio, 16 meses, 2 pagadas.
      final loan = Installment(
        description: 'Prestamo mama',
        category: 'prestamo',
        monthlyAmount: 50000,
        installmentCount: 16,
        paidCount: 2,
        startYear: 2026,
        startMonth: 6,
        kind: Installment.kindRecibido,
      );

      final junio = LoanAdjustment.forMonth([loan], 2026, 6);
      expect(junio.outgoing, 50000);
      expect(junio.incoming, 0);

      final julio = LoanAdjustment.forMonth([loan], 2026, 7);
      expect(julio.outgoing, 50000);

      final agosto = LoanAdjustment.forMonth([loan], 2026, 8);
      expect(agosto.outgoing, 50000);

      final mesSinCuota = LoanAdjustment.forMonth([loan], 2026, 5);
      expect(mesSinCuota.isZero, isTrue);
    });

    test('cuota "prestado" (dinero que preste) se ve como ingreso', () {
      final loan = Installment(
        description: 'Le preste a un amigo',
        category: 'otros',
        monthlyAmount: 20000,
        installmentCount: 4,
        startYear: 2026,
        startMonth: 3,
        kind: Installment.kindPrestado,
      );

      final adj = LoanAdjustment.forMonth([loan], 2026, 3);
      expect(adj.incoming, 20000);
      expect(adj.outgoing, 0);
      expect(adj.net, 20000);
    });

    test('suma varios prestamos del mismo mes', () {
      final a = Installment(
        description: 'A', category: 'otros', monthlyAmount: 10000,
        installmentCount: 3, startYear: 2026, startMonth: 1,
      );
      final b = Installment(
        description: 'B', category: 'otros', monthlyAmount: 5000,
        installmentCount: 3, startYear: 2026, startMonth: 1,
        kind: Installment.kindPrestado,
      );
      final adj = LoanAdjustment.forMonth([a, b], 2026, 1);
      expect(adj.outgoing, 10000);
      expect(adj.incoming, 5000);
      expect(adj.net, -5000);
    });

    test('las cuotas ya marcadas como pagadas igual se reflejan (son historicas)', () {
      final loan = Installment(
        description: 'Test', category: 'otros', monthlyAmount: 1000,
        installmentCount: 3, paidCount: 3, startYear: 2026, startMonth: 1,
      );
      final adj = LoanAdjustment.forMonth([loan], 2026, 1);
      expect(adj.outgoing, 1000);
    });
  });
}
