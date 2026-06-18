class ExpenseCategory {
  final int? id;
  final String key;
  final String displayName;
  final String section;

  ExpenseCategory({
    this.id,
    required this.key,
    required this.displayName,
    required this.section,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'key': key,
        'display_name': displayName,
        'section': section,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as int?,
        key: map['key'] as String,
        displayName: map['display_name'] as String,
        section: map['section'] as String,
      );
}
