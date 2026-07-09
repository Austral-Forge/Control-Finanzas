import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/installment.dart';
import '../../data/models/bank_connection.dart';
import '../../data/models/payment_method_totals.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final List<IncomeSource> incomeSources;
  final List<PaymentMethod> paymentMethods;
  final List<ExpenseCategory> expenseCategories;
  final List<Installment> installments;
  final List<BankConnection> bankConnections;
  final Map<int, PaymentMethodTotals> paymentMethodTotals;

  /// Totales por mes ('yyyy-MM') y medio de pago, para el desglose mensual.
  final Map<String, Map<int, PaymentMethodTotals>> monthlyMethodTotals;

  SettingsLoaded({
    required this.incomeSources,
    required this.paymentMethods,
    required this.expenseCategories,
    required this.installments,
    this.bankConnections = const [],
    this.paymentMethodTotals = const {},
    this.monthlyMethodTotals = const {},
  });

  SettingsLoaded copyWith({
    List<IncomeSource>? incomeSources,
    List<PaymentMethod>? paymentMethods,
    List<ExpenseCategory>? expenseCategories,
    List<Installment>? installments,
    List<BankConnection>? bankConnections,
    Map<int, PaymentMethodTotals>? paymentMethodTotals,
    Map<String, Map<int, PaymentMethodTotals>>? monthlyMethodTotals,
  }) {
    return SettingsLoaded(
      incomeSources: incomeSources ?? this.incomeSources,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      installments: installments ?? this.installments,
      bankConnections: bankConnections ?? this.bankConnections,
      paymentMethodTotals: paymentMethodTotals ?? this.paymentMethodTotals,
      monthlyMethodTotals: monthlyMethodTotals ?? this.monthlyMethodTotals,
    );
  }

  /// Totales de actividad para una conexión, según su medio de pago asociado.
  PaymentMethodTotals totalsFor(BankConnection connection) {
    final methodId = connection.paymentMethodId;
    if (methodId == null) return PaymentMethodTotals.empty;
    return paymentMethodTotals[methodId] ?? PaymentMethodTotals.empty;
  }

  /// Totales de una conexión en un mes específico ('yyyy-MM').
  PaymentMethodTotals monthlyTotalsFor(
      BankConnection connection, String monthKey) {
    final methodId = connection.paymentMethodId;
    if (methodId == null) return PaymentMethodTotals.empty;
    return monthlyMethodTotals[monthKey]?[methodId] ??
        PaymentMethodTotals.empty;
  }

  /// Balance neto de todas las instituciones conectadas en un mes.
  PaymentMethodTotals connectionsTotalsForMonth(String monthKey) {
    double income = 0;
    double cost = 0;
    for (final connection in bankConnections) {
      final totals = monthlyTotalsFor(connection, monthKey);
      income += totals.income;
      cost += totals.cost;
    }
    return PaymentMethodTotals(income: income, cost: cost);
  }
}

class SettingsError extends SettingsState {
  final String message;
  SettingsError({required this.message});
}
