class TransactionItem {
  final int? id;
  final String type; // 'income' o 'cost'
  final String category; // 'sueldo', 'ventas', 'pagos_tercero' para ingresos; 'tarjetas', 'prestamos', 'compras', 'pagos_basicos', 'otros' para costos.
  final double amount;
  final String description;
  final DateTime date;

  TransactionItem({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as int?,
      type: map['type'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  TransactionItem copyWith({
    int? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
    );
  }
}
