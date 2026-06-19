import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  Future<void> _onLoadFinanceSummaries(
    LoadFinanceSummaries event,
    Emitter<FinanceState> emit,
  ) async {
    emit(FinanceLoading());
    try {
      final summaries = await financeRepository.getMonthlySummaries();
      emit(FinanceLoaded(summaries: summaries));
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
        emit(currentState.copyWith(
          summaries: summaries,
          selectedMonthTransactions: transactions,
          isDetailsLoading: false,
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

        final txnYear = event.transaction.date.year;
        final txnMonth = event.transaction.date.month;

        if (currentState.selectedYear == txnYear &&
            currentState.selectedMonth == txnMonth) {
          final transactions =
              await financeRepository.getTransactionsForMonth(txnYear, txnMonth);
          emit(currentState.copyWith(
            summaries: summaries,
            selectedMonthTransactions: transactions,
          ));
        } else {
          emit(currentState.copyWith(summaries: summaries));
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
}
