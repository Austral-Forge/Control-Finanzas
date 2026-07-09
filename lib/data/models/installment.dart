/// Un compromiso pactado en cuotas. Solo sirve como proyección: alimenta la
/// tarjeta del mes siguiente, no genera transacciones reales automáticamente.
///
/// [kind] distingue la dirección del dinero:
/// - `pago`: compra o deuda propia, las cuotas son egresos futuros.
/// - `recibido`: dinero que me prestaron, las cuotas que devuelvo son egresos.
/// - `prestado`: dinero que presté, las cuotas que me pagan son ingresos.
class Installment {
  static const String kindPago = 'pago';
  static const String kindPrestado = 'prestado';
  static const String kindRecibido = 'recibido';

  final int? id;
  final String description;
  final String category;
  final int? paymentMethodId;
  final double monthlyAmount;
  final int installmentCount;
  final int paidCount;
  final int startYear;
  final int startMonth;
  final String kind;

  Installment({
    this.id,
    required this.description,
    required this.category,
    this.paymentMethodId,
    required this.monthlyAmount,
    required this.installmentCount,
    this.paidCount = 0,
    required this.startYear,
    required this.startMonth,
    this.kind = kindPago,
  });

  /// `true` si las cuotas de este compromiso son dinero que entra (me deben).
  bool get isIncoming => kind == kindPrestado;

  /// Cuotas que aún faltan por pagar.
  int get remainingCount => installmentCount - paidCount;

  /// Saldo pendiente total.
  double get remainingBalance => remainingCount * monthlyAmount;

  /// Costo total del compromiso.
  double get totalAmount => installmentCount * monthlyAmount;

  bool get isCompleted => remainingCount <= 0;

  /// Índice (1-based) de la cuota que cae en [year]/[month], o `null` si no hay
  /// ninguna ese mes. La cuota nº1 vence en `startYear/startMonth`.
  int? _installmentIndexFor(int year, int month) {
    final monthsFromStart =
        (year - startYear) * 12 + (month - startMonth);
    if (monthsFromStart < 0) return null;
    final index = monthsFromStart + 1;
    if (index > installmentCount) return null;
    return index;
  }

  /// Monto a proyectar para [year]/[month]: el valor de la cuota si ese mes
  /// corresponde a una cuota **pendiente** (aún no pagada), si no `0`.
  double dueAmountForMonth(int year, int month) {
    final index = _installmentIndexFor(year, month);
    if (index == null) return 0;
    return index > paidCount ? monthlyAmount : 0;
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'description': description,
        'category': category,
        'payment_method_id': paymentMethodId,
        'monthly_amount': monthlyAmount,
        'installment_count': installmentCount,
        'paid_count': paidCount,
        'start_year': startYear,
        'start_month': startMonth,
        'kind': kind,
      };

  factory Installment.fromMap(Map<String, dynamic> map) => Installment(
        id: map['id'] as int?,
        description: map['description'] as String,
        category: map['category'] as String,
        paymentMethodId: map['payment_method_id'] as int?,
        monthlyAmount: (map['monthly_amount'] as num).toDouble(),
        installmentCount: map['installment_count'] as int,
        paidCount: map['paid_count'] as int? ?? 0,
        startYear: map['start_year'] as int,
        startMonth: map['start_month'] as int,
        kind: map['kind'] as String? ?? kindPago,
      );

  Installment copyWith({
    int? id,
    String? description,
    String? category,
    int? paymentMethodId,
    double? monthlyAmount,
    int? installmentCount,
    int? paidCount,
    int? startYear,
    int? startMonth,
    String? kind,
  }) =>
      Installment(
        id: id ?? this.id,
        description: description ?? this.description,
        category: category ?? this.category,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        monthlyAmount: monthlyAmount ?? this.monthlyAmount,
        installmentCount: installmentCount ?? this.installmentCount,
        paidCount: paidCount ?? this.paidCount,
        startYear: startYear ?? this.startYear,
        startMonth: startMonth ?? this.startMonth,
        kind: kind ?? this.kind,
      );
}
