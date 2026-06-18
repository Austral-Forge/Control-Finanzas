abstract class SettingsEvent {}

class LoadSettings extends SettingsEvent {}

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
