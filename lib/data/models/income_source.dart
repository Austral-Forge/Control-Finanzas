class IncomeSource {
  final int? id;
  final String name;

  IncomeSource({this.id, required this.name});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
      };

  factory IncomeSource.fromMap(Map<String, dynamic> map) => IncomeSource(
        id: map['id'] as int?,
        name: map['name'] as String,
      );
}
