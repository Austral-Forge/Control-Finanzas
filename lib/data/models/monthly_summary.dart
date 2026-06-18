class MonthlySummary {
  final int year;
  final int month;
  final double totalIncome;
  final double totalCost;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalCost,
  });

  double get balance => totalIncome - totalCost;
  bool get isDeficit => balance < 0;

  DateTime get date => DateTime(year, month);
}
