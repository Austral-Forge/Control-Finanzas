import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final List<IncomeSource> incomeSources;
  final List<PaymentMethod> paymentMethods;
  final List<ExpenseCategory> expenseCategories;

  SettingsLoaded({
    required this.incomeSources,
    required this.paymentMethods,
    required this.expenseCategories,
  });

  SettingsLoaded copyWith({
    List<IncomeSource>? incomeSources,
    List<PaymentMethod>? paymentMethods,
    List<ExpenseCategory>? expenseCategories,
  }) {
    return SettingsLoaded(
      incomeSources: incomeSources ?? this.incomeSources,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      expenseCategories: expenseCategories ?? this.expenseCategories,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError({required this.message});
}
