import 'monthly_summary.dart';
import 'savings_confirmation.dart';

class MonthlyProjection {
  final MonthlySummary summary;
  final double previousSavings;
  final bool savingsConfirmed;

  const MonthlyProjection({
    required this.summary,
    required this.previousSavings,
    this.savingsConfirmed = false,
  });

  double get carriedSavings => previousSavings > 0 ? previousSavings : 0;

  double get effectiveIncome => summary.totalIncome + carriedSavings;

  double get savingsPotential => effectiveIncome - summary.totalCost;

  double get savingsRate =>
      summary.totalIncome > 0 ? summary.balance / summary.totalIncome : 0;

  bool get hasCarriedSavings => carriedSavings > 0;

  static List<MonthlyProjection> fromChronological(
    List<MonthlySummary> chronological, {
    Map<String, SavingsConfirmation> confirmations = const {},
  }) {
    final projections = <MonthlyProjection>[];
    var accumulated = 0.0;
    for (final summary in chronological) {
      final key = '${summary.year}-${summary.month}';
      final confirmation = confirmations[key];
      projections.add(MonthlyProjection(
        summary: summary,
        previousSavings:
            confirmation != null ? confirmation.confirmedAmount : accumulated,
        savingsConfirmed: confirmation != null,
      ));
      accumulated += summary.balance;
    }
    return projections;
  }
}
