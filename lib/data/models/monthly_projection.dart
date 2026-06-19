import 'monthly_summary.dart';

/// Proyección financiera de un mes que incorpora el ahorro acumulado de los
/// meses anteriores como parte del ingreso disponible.
class MonthlyProjection {
  final MonthlySummary summary;

  /// Ahorro neto acumulado de todos los meses anteriores a este.
  final double previousSavings;

  const MonthlyProjection({
    required this.summary,
    required this.previousSavings,
  });

  /// El ahorro anterior solo suma cuando es positivo (un déficit previo no
  /// incrementa el ingreso disponible del mes actual).
  double get carriedSavings => previousSavings > 0 ? previousSavings : 0;

  /// Ingreso del mes más el ahorro arrastrado de meses anteriores.
  double get effectiveIncome => summary.totalIncome + carriedSavings;

  /// Cuánto podría ahorrarse este mes considerando el ingreso efectivo.
  double get savingsPotential => effectiveIncome - summary.totalCost;

  /// Tasa de ahorro del mes respecto a su ingreso propio (0..1).
  double get savingsRate =>
      summary.totalIncome > 0 ? summary.balance / summary.totalIncome : 0;

  bool get hasCarriedSavings => carriedSavings > 0;

  /// Construye las proyecciones de una lista de resúmenes en orden cronológico
  /// (del más antiguo al más reciente), acumulando el ahorro previo de cada mes.
  static List<MonthlyProjection> fromChronological(
    List<MonthlySummary> chronological,
  ) {
    final projections = <MonthlyProjection>[];
    var accumulated = 0.0;
    for (final summary in chronological) {
      projections.add(MonthlyProjection(
        summary: summary,
        previousSavings: accumulated,
      ));
      accumulated += summary.balance;
    }
    return projections;
  }
}
