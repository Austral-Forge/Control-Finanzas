class PaymentMethod {
  final int? id;
  final String name;

  PaymentMethod({this.id, required this.name});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };

  factory PaymentMethod.fromMap(Map<String, dynamic> map) => PaymentMethod(
        id: map['id'] as int?,
        name: map['name'] as String,
      );
}
