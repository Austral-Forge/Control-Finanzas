import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FinanceRepository financeRepository;

  SettingsBloc({required this.financeRepository}) : super(SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<AddIncomeSourceEvent>(_onAddIncomeSource);
    on<DeleteIncomeSourceEvent>(_onDeleteIncomeSource);
    on<AddPaymentMethodEvent>(_onAddPaymentMethod);
    on<DeletePaymentMethodEvent>(_onDeletePaymentMethod);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      final incomeSources = await financeRepository.getIncomeSources();
      final paymentMethods = await financeRepository.getPaymentMethods();
      final expenseCategories = await financeRepository.getExpenseCategories();
      emit(SettingsLoaded(
        incomeSources: incomeSources,
        paymentMethods: paymentMethods,
        expenseCategories: expenseCategories,
      ));
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onAddIncomeSource(
    AddIncomeSourceEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.addIncomeSource(IncomeSource(name: event.name));
      final incomeSources = await financeRepository.getIncomeSources();
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(incomeSources: incomeSources));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteIncomeSource(
    DeleteIncomeSourceEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.deleteIncomeSource(event.id);
      final incomeSources = await financeRepository.getIncomeSources();
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(incomeSources: incomeSources));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethodEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.addPaymentMethod(PaymentMethod(name: event.name));
      final paymentMethods = await financeRepository.getPaymentMethods();
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(paymentMethods: paymentMethods));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onDeletePaymentMethod(
    DeletePaymentMethodEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.deletePaymentMethod(event.id);
      final paymentMethods = await financeRepository.getPaymentMethods();
      final current = state;
      if (current is SettingsLoaded) {
        emit(current.copyWith(paymentMethods: paymentMethods));
      }
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }
}
