import '../../data/models/monthly_summary.dart';
import '../../data/models/transaction_item.dart';

abstract class FinanceState {}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final List<MonthlySummary> summaries;
  final int? selectedYear;
  final int? selectedMonth;
  final List<TransactionItem>? selectedMonthTransactions;
  final bool isDetailsLoading;

  FinanceLoaded({
    required this.summaries,
    this.selectedYear,
    this.selectedMonth,
    this.selectedMonthTransactions,
    this.isDetailsLoading = false,
  });

  FinanceLoaded copyWith({
    List<MonthlySummary>? summaries,
    int? selectedYear,
    int? selectedMonth,
    List<TransactionItem>? selectedMonthTransactions,
    bool? isDetailsLoading,
  }) {
    return FinanceLoaded(
      summaries: summaries ?? this.summaries,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedMonthTransactions: selectedMonthTransactions ?? this.selectedMonthTransactions,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
    );
  }
}

class FinanceError extends FinanceState {
  final String message;

  FinanceError({required this.message});
}
