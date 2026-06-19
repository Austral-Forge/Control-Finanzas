import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/installment.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final List<IncomeSource> incomeSources;
  final List<PaymentMethod> paymentMethods;
  final List<ExpenseCategory> expenseCategories;
  final List<Installment> installments;

  SettingsLoaded({
    required this.incomeSources,
    required this.paymentMethods,
    required this.expenseCategories,
    required this.installments,
  });

  SettingsLoaded copyWith({
    List<IncomeSource>? incomeSources,
    List<PaymentMethod>? paymentMethods,
    List<ExpenseCategory>? expenseCategories,
    List<Installment>? installments,
  }) {
    return SettingsLoaded(
      incomeSources: incomeSources ?? this.incomeSources,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      installments: installments ?? this.installments,
    );
  }
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError({required this.message});
}
