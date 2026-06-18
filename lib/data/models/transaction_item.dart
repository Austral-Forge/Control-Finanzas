class TransactionItem {
  final int? id;
  final String type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final int? parentId;
  final int? incomeSourceId;
  final int? paymentMethodId;
  final List<TransactionItem> children;

  TransactionItem({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    this.parentId,
    this.incomeSourceId,
    this.paymentMethodId,
    this.children = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'parent_id': parentId,
      'income_source_id': incomeSourceId,
      'payment_method_id': paymentMethodId,
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
      parentId: map['parent_id'] as int?,
      incomeSourceId: map['income_source_id'] as int?,
      paymentMethodId: map['payment_method_id'] as int?,
    );
  }

  TransactionItem copyWith({
    int? id,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
    int? parentId,
    int? incomeSourceId,
    int? paymentMethodId,
    List<TransactionItem>? children,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      parentId: parentId ?? this.parentId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      children: children ?? this.children,
    );
  }

  bool get hasChildren => children.isNotEmpty;
  bool get isChild => parentId != null;
}
