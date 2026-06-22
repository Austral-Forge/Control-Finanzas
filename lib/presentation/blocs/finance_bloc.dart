import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/savings_confirmation.dart';
import '../../domain/repositories/finance_repository.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final FinanceRepository financeRepository;

  FinanceBloc({required this.financeRepository}) : super(FinanceInitial()) {
    on<LoadFinanceSummaries>(_onLoadFinanceSummaries);
    on<LoadMonthDetails>(_onLoadMonthDetails);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<AddChildTransaction>(_onAddChildTransaction);
    on<CheckPendingSavingsConfirmation>(_onCheckPendingSavingsConfirmation);
    on<ConfirmSavings>(_onConfirmSavings);
  }

  Future<Map<String, SavingsConfirmation>> _loadConfirmationsMap() async {
    final list = await financeRepository.getAllSavingsConfirmations();
    return {for (final c in list) c.key: c};
  }

  Future<void> _onLoadFinanceSummaries(
    LoadFinanceSummaries event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoading());
    try {
      final summaries = await financeRepository.getMonthlySummaries();
      final confirmations = await _loadConfirmationsMap();
      final hasPending = _checkPending(summaries, confirmations);
      emit(FinanceLoaded(
        summaries: summaries,
        savingsConfirmations: confirmations,
        hasPendingSavingsConfirmation: hasPending,
      ));
    } catch (e) {
      emit(FinanceError(message: e.toString()));
    }
  }

  Future<void> _onLoadMonthDetails(
    LoadMonthDetails event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      emit(currentState.copyWith(
        isDetailsLoading: true,
        selectedYear: event.year,
        selectedMonth: event.month,
      ));
      try {
        final transactions = await financeRepository.getTransactionsForMonth(
          event.year,
          event.month,
        );
        final summaries = await financeRepository.getMonthlySummaries();

        final prevMonth = event.month == 1 ? 12 : event.month - 1;
        final prevYear = event.month == 1 ? event.year - 1 : event.year;
        final previousTransactions =
            await financeRepository.getTransactionsForMonth(prevYear, prevMonth);

        emit(currentState.copyWith(
          summaries: summaries,
          selectedMonthTransactions: transactions,
          isDetailsLoading: false,
          previousMonthTransactions: previousTransactions,
          previousYear: prevYear,
          previousMonth: prevMonth,
        ));
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      try {
        await financeRepository.addTransaction(event.transaction);
        final summaries = await financeRepository.getMonthlySummaries();
        final confirmations = await _loadConfirmationsMap();
        final hasPending = _checkPending(summaries, confirmations);

        final txnYear = event.transaction.date.year;
        final txnMonth = event.transaction.date.month;

        if (currentState.selectedYear == txnYear &&
            currentState.selectedMonth == txnMonth) {
          final transactions =
              await financeRepository.getTransactionsForMonth(txnYear, txnMonth);
          emit(currentState.copyWith(
            summaries: summaries,
            selectedMonthTransactions: transactions,
            savingsConfirmations: confirmations,
            hasPendingSavingsConfirmation: hasPending,
          ));
        } else {
          emit(currentState.copyWith(
            summaries: summaries,
            savingsConfirmations: confirmations,
            hasPendingSavingsConfirmation: hasPending,
          ));
        }
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      try {
        await financeRepository.updateTransaction(event.transaction);
        final summaries = await financeRepository.getMonthlySummaries();
        final transactions = await financeRepository.getTransactionsForMonth(
          event.year,
          event.month,
        );
        emit(currentState.copyWith(
          summaries: summaries,
          selectedMonthTransactions: transactions,
        ));
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      try {
        await financeRepository.deleteTransaction(event.id);
        final summaries = await financeRepository.getMonthlySummaries();
        final transactions = await financeRepository.getTransactionsForMonth(
          event.year,
          event.month,
        );

        emit(currentState.copyWith(
          summaries: summaries,
          selectedMonthTransactions: transactions,
        ));
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  Future<void> _onAddChildTransaction(
    AddChildTransaction event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      try {
        await financeRepository.addTransaction(event.child);
        final summaries = await financeRepository.getMonthlySummaries();
        final transactions = await financeRepository.getTransactionsForMonth(
          event.year,
          event.month,
        );
        emit(currentState.copyWith(
          summaries: summaries,
          selectedMonthTransactions: transactions,
        ));
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  Future<void> _onCheckPendingSavingsConfirmation(
    CheckPendingSavingsConfirmation event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      final confirmations = await _loadConfirmationsMap();
      final hasPending = _checkPending(currentState.summaries, confirmations);
      emit(currentState.copyWith(
        savingsConfirmations: confirmations,
        hasPendingSavingsConfirmation: hasPending,
      ));
    }
  }

  Future<void> _onConfirmSavings(
    ConfirmSavings event,
    Emitter<FinanceState> emit,
  ) async {
    final currentState = state;
    if (currentState is FinanceLoaded) {
      try {
        await financeRepository.saveSavingsConfirmation(SavingsConfirmation(
          year: event.year,
          month: event.month,
          originalAmount: event.originalAmount,
          confirmedAmount: event.confirmedAmount,
          confirmedAt: DateTime.now(),
        ));
        final summaries = await financeRepository.getMonthlySummaries();
        final confirmations = await _loadConfirmationsMap();
        emit(currentState.copyWith(
          summaries: summaries,
          savingsConfirmations: confirmations,
          hasPendingSavingsConfirmation: false,
        ));
      } catch (e) {
        emit(FinanceError(message: e.toString()));
      }
    }
  }

  bool _checkPending(
    List<dynamic> summaries,
    Map<String, SavingsConfirmation> confirmations,
  ) {
    if (summaries.isEmpty) return false;
    final now = DateTime.now();
    final key = '${now.year}-${now.month}';
    if (confirmations.containsKey(key)) return false;
    final totalSavings =
        summaries.fold<double>(0.0, (sum, s) => sum + (s.balance as double));
    return totalSavings > 0;
  }
}
