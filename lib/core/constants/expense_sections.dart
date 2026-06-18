enum ExpenseSection { indispensable, recurrente, extraordinario }

class ExpenseSections {
  static const Map<String, ExpenseSection> categoryToSection = {
    'arriendo_dividendo': ExpenseSection.indispensable,
    'luz': ExpenseSection.indispensable,
    'agua': ExpenseSection.indispensable,
    'gas': ExpenseSection.indispensable,
    'internet': ExpenseSection.indispensable,
    'tarjeta_credito': ExpenseSection.recurrente,
    'prestamo': ExpenseSection.recurrente,
    'seguro': ExpenseSection.recurrente,
    'suscripcion': ExpenseSection.recurrente,
    'compras': ExpenseSection.extraordinario,
    'salidas': ExpenseSection.extraordinario,
    'regalos': ExpenseSection.extraordinario,
    'medico': ExpenseSection.extraordinario,
    'otros': ExpenseSection.extraordinario,
  };

  static ExpenseSection getSection(String category) {
    return categoryToSection[category] ?? ExpenseSection.extraordinario;
  }

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

  static String getCategoryDisplayName(String category) {
    const names = {
      'arriendo_dividendo': 'Arriendo / Dividendo',
      'luz': 'Luz',
      'agua': 'Agua',
      'gas': 'Gas',
      'internet': 'Internet',
      'tarjeta_credito': 'Tarjeta de Crédito',
      'prestamo': 'Préstamo',
      'seguro': 'Seguro',
      'suscripcion': 'Suscripción',
      'compras': 'Compras',
      'salidas': 'Salidas',
      'regalos': 'Regalos',
      'medico': 'Médico',
      'otros': 'Otros',
    };
    return names[category] ?? category;
  }

  static List<String> getCategoriesForSection(ExpenseSection section) {
    return categoryToSection.entries
        .where((e) => e.value == section)
        .map((e) => e.key)
        .toList();
  }
}
