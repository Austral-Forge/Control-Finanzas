import '../../data/models/expense_category.dart';
import 'expense_sections.dart';

/// Búsqueda en memoria de categorías de gasto a partir de la lista cargada
/// desde la base de datos (la fuente de verdad). Reemplaza los mapas
/// hardcodeados de sección/nombre que existían cuando las categorías eran fijas.
class ExpenseCategoryLookup {
  final Map<String, ExpenseCategory> _byKey;

  ExpenseCategoryLookup(List<ExpenseCategory> categories)
      : _byKey = {for (final c in categories) c.key: c};

  /// Sección de una categoría; `extraordinario` si la key es desconocida
  /// (p.ej. una transacción antigua cuya categoría fue eliminada).
  ExpenseSection sectionOf(String key) {
    final category = _byKey[key];
    if (category == null) return ExpenseSection.extraordinario;
    return ExpenseSections.parseSection(category.section);
  }

  /// Nombre legible de una categoría; la propia key como fallback.
  String displayNameOf(String key) => _byKey[key]?.displayName ?? key;
}
