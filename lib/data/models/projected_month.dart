import 'installment.dart';

/// Proyección del mes siguiente al último mes con datos reales.
///
/// Parte del saldo arrastrado de los meses anteriores (positivo o negativo) y
/// le resta las cuotas comprometidas que vencen ese mes. No asume ingresos
/// futuros (decisión de producto).
class ProjectedMonth {
  final int year;
  final int month;

  /// Ahorro neto acumulado de todos los meses reales anteriores.
  final double carriedBalance;

  /// Cuotas con un pago pendiente en este mes.
  final List<Installment> dueInstallments;

  final bool savingsConfirmed;

  const ProjectedMonth({
    required this.year,
    required this.month,
    required this.carriedBalance,
    required this.dueInstallments,
    this.savingsConfirmed = false,
  });

  /// Suma de las cuotas que debo pagar este mes (compras, deudas, préstamos
  /// recibidos).
  double get projectedExpenses => dueInstallments
      .where((i) => !i.isIncoming)
      .fold(0.0, (sum, i) => sum + i.dueAmountForMonth(year, month));

  /// Suma de las cuotas que me pagan este mes (dinero que presté).
  double get projectedIncomes => dueInstallments
      .where((i) => i.isIncoming)
      .fold(0.0, (sum, i) => sum + i.dueAmountForMonth(year, month));

  /// Saldo proyectado al cierre del mes.
  double get projectedBalance =>
      carriedBalance + projectedIncomes - projectedExpenses;

  bool get isDeficit => projectedBalance < 0;

  bool get hasInstallments => dueInstallments.isNotEmpty;

  /// Construye la proyección del mes siguiente a [lastYear]/[lastMonth] tomando
  /// solo las cuotas con un pago pendiente ese mes.
  factory ProjectedMonth.next({
    required int lastYear,
    required int lastMonth,
    required double carriedBalance,
    required List<Installment> installments,
    bool savingsConfirmed = false,
  }) {
    final nextMonth = lastMonth == 12 ? 1 : lastMonth + 1;
    final nextYear = lastMonth == 12 ? lastYear + 1 : lastYear;
    final due = installments
        .where((i) => i.dueAmountForMonth(nextYear, nextMonth) > 0)
        .toList();
    return ProjectedMonth(
      year: nextYear,
      month: nextMonth,
      carriedBalance: carriedBalance,
      dueInstallments: due,
      savingsConfirmed: savingsConfirmed,
    );
  }

  /// Construye una cadena de proyecciones, una por cada mes desde el
  /// siguiente a [lastYear]/[lastMonth] hasta el último mes que tenga alguna
  /// cuota pendiente (ej: un préstamo a 16 meses genera 16 tarjetas, no solo
  /// la primera). Si no hay cuotas pendientes futuras, devuelve un único mes
  /// (igual que [ProjectedMonth.next]). El saldo se arrastra de un mes al
  /// siguiente dentro de la cadena.
  static List<ProjectedMonth> series({
    required int lastYear,
    required int lastMonth,
    required double carriedBalance,
    required List<Installment> installments,
    bool savingsConfirmed = false,
  }) {
    var year = lastMonth == 12 ? lastYear + 1 : lastYear;
    var month = lastMonth == 12 ? 1 : lastMonth + 1;

    DateTime lastPending = DateTime(year, month);
    for (final inst in installments) {
      for (final entry in inst.schedule()) {
        if (entry.isPaid) continue;
        final due = DateTime(entry.year, entry.month);
        if (due.isAfter(lastPending)) lastPending = due;
      }
    }

    final result = <ProjectedMonth>[];
    var balance = carriedBalance;
    var isFirst = true;
    while (!DateTime(year, month).isAfter(lastPending)) {
      final due = installments
          .where((i) => i.dueAmountForMonth(year, month) > 0)
          .toList();
      final pm = ProjectedMonth(
        year: year,
        month: month,
        carriedBalance: balance,
        dueInstallments: due,
        savingsConfirmed: isFirst ? savingsConfirmed : true,
      );
      result.add(pm);
      balance = pm.projectedBalance;
      isFirst = false;

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return result;
  }
}
