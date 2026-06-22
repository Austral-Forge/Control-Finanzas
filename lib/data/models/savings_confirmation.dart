class SavingsConfirmation {
  final int? id;
  final int year;
  final int month;
  final double originalAmount;
  final double confirmedAmount;
  final DateTime confirmedAt;

  const SavingsConfirmation({
    this.id,
    required this.year,
    required this.month,
    required this.originalAmount,
    required this.confirmedAmount,
    required this.confirmedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'year': year,
        'month': month,
        'original_amount': originalAmount,
        'confirmed_amount': confirmedAmount,
        'confirmed_at': confirmedAt.toIso8601String(),
      };

  factory SavingsConfirmation.fromMap(Map<String, dynamic> map) =>
      SavingsConfirmation(
        id: map['id'] as int?,
        year: map['year'] as int,
        month: map['month'] as int,
        originalAmount: (map['original_amount'] as num).toDouble(),
        confirmedAmount: (map['confirmed_amount'] as num).toDouble(),
        confirmedAt: DateTime.parse(map['confirmed_at'] as String),
      );

  SavingsConfirmation copyWith({
    int? id,
    int? year,
    int? month,
    double? originalAmount,
    double? confirmedAmount,
    DateTime? confirmedAt,
  }) =>
      SavingsConfirmation(
        id: id ?? this.id,
        year: year ?? this.year,
        month: month ?? this.month,
        originalAmount: originalAmount ?? this.originalAmount,
        confirmedAmount: confirmedAmount ?? this.confirmedAmount,
        confirmedAt: confirmedAt ?? this.confirmedAt,
      );

  String get key => '$year-$month';
}
