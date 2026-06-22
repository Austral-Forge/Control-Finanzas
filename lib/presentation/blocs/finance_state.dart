import '../../data/models/monthly_summary.dart';
import '../../data/models/savings_confirmation.dart';
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
  final bool hasPendingSavingsConfirmation;
  final Map<String, SavingsConfirmation> savingsConfirmations;
  final List<TransactionItem>? previousMonthTransactions;
  final int? previousYear;
  final int? previousMonth;

  FinanceLoaded({
    required this.summaries,
    this.selectedYear,
    this.selectedMonth,
    this.selectedMonthTransactions,
    this.isDetailsLoading = false,
    this.hasPendingSavingsConfirmation = false,
    this.savingsConfirmations = const {},
    this.previousMonthTransactions,
    this.previousYear,
    this.previousMonth,
  });

  FinanceLoaded copyWith({
    List<MonthlySummary>? summaries,
    int? selectedYear,
    int? selectedMonth,
    List<TransactionItem>? selectedMonthTransactions,
    bool? isDetailsLoading,
    bool? hasPendingSavingsConfirmation,
    Map<String, SavingsConfirmation>? savingsConfirmations,
    List<TransactionItem>? previousMonthTransactions,
    int? previousYear,
    int? previousMonth,
  }) {
    return FinanceLoaded(
      summaries: summaries ?? this.summaries,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedMonthTransactions:
          selectedMonthTransactions ?? this.selectedMonthTransactions,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      hasPendingSavingsConfirmation:
          hasPendingSavingsConfirmation ?? this.hasPendingSavingsConfirmation,
      savingsConfirmations:
          savingsConfirmations ?? this.savingsConfirmations,
      previousMonthTransactions:
          previousMonthTransactions ?? this.previousMonthTransactions,
      previousYear: previousYear ?? this.previousYear,
      previousMonth: previousMonth ?? this.previousMonth,
    );
  }
}

class FinanceError extends FinanceState {
  final String message;

  FinanceError({required this.message});
}
