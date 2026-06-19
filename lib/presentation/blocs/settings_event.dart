import '../../data/models/expense_category.dart';
import '../../data/models/installment.dart';

abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

// --- Expense categories ---

class AddExpenseCategoryEvent extends SettingsEvent {
  final String displayName;
  final String section; // 'indispensable' | 'recurrente' | 'extraordinario'
  AddExpenseCategoryEvent({required this.displayName, required this.section});
}

class UpdateExpenseCategoryEvent extends SettingsEvent {
  final ExpenseCategory category;
  UpdateExpenseCategoryEvent({required this.category});
}

class DeleteExpenseCategoryEvent extends SettingsEvent {
  final int id;
  DeleteExpenseCategoryEvent({required this.id});
}

// --- Installments ---

class AddInstallmentEvent extends SettingsEvent {
  final Installment installment;
  AddInstallmentEvent({required this.installment});
}

class UpdateInstallmentEvent extends SettingsEvent {
  final Installment installment;
  UpdateInstallmentEvent({required this.installment});
}

class DeleteInstallmentEvent extends SettingsEvent {
  final int id;
  DeleteInstallmentEvent({required this.id});
}

class AddIncomeSourceEvent extends SettingsEvent {
  final String name;
  AddIncomeSourceEvent({required this.name});
}

class DeleteIncomeSourceEvent extends SettingsEvent {
  final int id;
  DeleteIncomeSourceEvent({required this.id});
}

class AddPaymentMethodEvent extends SettingsEvent {
  final String name;
  AddPaymentMethodEvent({required this.name});
}

class DeletePaymentMethodEvent extends SettingsEvent {
  final int id;
  DeletePaymentMethodEvent({required this.id});
}
