import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_summary.freezed.dart';
part 'monthly_summary.g.dart';

@freezed
class MonthlySummary with _$MonthlySummary {
  const factory MonthlySummary({
    required int year,
    required int month,
    required double totalIncome,
    required double totalCost,
  }) = _MonthlySummary;

  const MonthlySummary._();

  factory MonthlySummary.fromJson(Map<String, dynamic> json) =>
      _$MonthlySummaryFromJson(json);

  double get balance => totalIncome - totalCost;
  bool get isDeficit => balance < 0;
  DateTime get date => DateTime(year, month);
}
