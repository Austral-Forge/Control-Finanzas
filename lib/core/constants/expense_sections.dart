import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Secciones estructurales de gasto. Son fijas (no editables por el usuario);
/// las categorías dentro de cada sección sí son configurables.
enum ExpenseSection { indispensable, recurrente, extraordinario }

class ExpenseSections {
  const ExpenseSections._();

  static String getSectionDisplayName(ExpenseSection section) {
    switch (section) {
      case ExpenseSection.indispensable:
        return 'Gastos Indispensables';
      case ExpenseSection.recurrente:
        return 'Gastos Recurrentes';
      case ExpenseSection.extraordinario:
        return 'Gastos Extraordinarios';
    }
  }

  /// Color asociado a cada sección, reutilizado en gráficos y badges.
  static Color colorOf(ExpenseSection section) {
    switch (section) {
      case ExpenseSection.indispensable:
        return AppTheme.cost;
      case ExpenseSection.recurrente:
        return AppTheme.primary;
      case ExpenseSection.extraordinario:
        return AppTheme.savings;
    }
  }

  /// Convierte el valor persistido en DB (`'indispensable'`, etc.) al enum.
  /// Cae en `extraordinario` ante valores desconocidos.
  static ExpenseSection parseSection(String value) {
    return ExpenseSection.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ExpenseSection.extraordinario,
    );
  }

  /// Genera una `key` slug a partir de un nombre legible: minúsculas, sin
  /// acentos, espacios y símbolos reemplazados por `_`.
  static String slugify(String name) {
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    };
    var slug = name.trim().toLowerCase();
    accents.forEach((from, to) => slug = slug.replaceAll(from, to));
    slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    slug = slug.replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'categoria' : slug;
  }
}
