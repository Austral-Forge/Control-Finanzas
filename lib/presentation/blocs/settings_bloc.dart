import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/expense_sections.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../data/models/expense_category.dart';
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
    on<AddExpenseCategoryEvent>(_onAddExpenseCategory);
    on<UpdateExpenseCategoryEvent>(_onUpdateExpenseCategory);
    on<DeleteExpenseCategoryEvent>(_onDeleteExpenseCategory);
    on<AddInstallmentEvent>(_onAddInstallment);
    on<UpdateInstallmentEvent>(_onUpdateInstallment);
    on<DeleteInstallmentEvent>(_onDeleteInstallment);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());
    try {
      emit(await _buildLoadedState());
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  /// Reconstruye el estado cargado leyendo todas las colecciones del repo.
  Future<SettingsLoaded> _buildLoadedState() async {
    final incomeSources = await financeRepository.getIncomeSources();
    final paymentMethods = await financeRepository.getPaymentMethods();
    final expenseCategories = await financeRepository.getExpenseCategories();
    final installments = await financeRepository.getInstallments();
    return SettingsLoaded(
      incomeSources: incomeSources,
      paymentMethods: paymentMethods,
      expenseCategories: expenseCategories,
      installments: installments,
    );
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

  // --- Expense categories ---

  Future<void> _onAddExpenseCategory(
    AddExpenseCategoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final key = await _uniqueCategoryKey(event.displayName);
      await financeRepository.addExpenseCategory(ExpenseCategory(
        key: key,
        displayName: event.displayName.trim(),
        section: event.section,
      ));
      await _reloadCategories(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateExpenseCategory(
    UpdateExpenseCategoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.updateExpenseCategory(event.category);
      await _reloadCategories(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteExpenseCategory(
    DeleteExpenseCategoryEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.deleteExpenseCategory(event.id);
      await _reloadCategories(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _reloadCategories(Emitter<SettingsState> emit) async {
    final categories = await financeRepository.getExpenseCategories();
    final current = state;
    if (current is SettingsLoaded) {
      emit(current.copyWith(expenseCategories: categories));
    }
  }

  /// Genera un slug único para una categoría, agregando un sufijo numérico si
  /// ya existe (p.ej. `mascotas`, `mascotas_2`).
  Future<String> _uniqueCategoryKey(String displayName) async {
    final base = ExpenseSections.slugify(displayName);
    var key = base;
    var suffix = 2;
    while (await financeRepository.expenseCategoryKeyExists(key)) {
      key = '${base}_$suffix';
      suffix++;
    }
    return key;
  }

  // --- Installments ---

  Future<void> _onAddInstallment(
    AddInstallmentEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.addInstallment(event.installment);
      await _reloadInstallments(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onUpdateInstallment(
    UpdateInstallmentEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.updateInstallment(event.installment);
      await _reloadInstallments(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteInstallment(
    DeleteInstallmentEvent event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await financeRepository.deleteInstallment(event.id);
      await _reloadInstallments(emit);
    } catch (e) {
      emit(SettingsError(message: e.toString()));
    }
  }

  Future<void> _reloadInstallments(Emitter<SettingsState> emit) async {
    final installments = await financeRepository.getInstallments();
    final current = state;
    if (current is SettingsLoaded) {
      emit(current.copyWith(installments: installments));
    }
  }
}
