/// Totales históricos de ingresos y gastos registrados con un medio de pago.
/// Se usa para medir la actividad de cada institución vinculada.
class PaymentMethodTotals {
  final double income;
  final double cost;

  const PaymentMethodTotals({required this.income, required this.cost});

  static const empty = PaymentMethodTotals(income: 0, cost: 0);

  double get balance => income - cost;
}
