class OnboardingDefaults {
  OnboardingDefaults._();

  static const List<String> incomeSources = [
    'Sueldo',
    'Ventas',
    'Comisiones Bancarias',
    'Acciones',
    'Arriendos',
    'Freelance',
    'Bonos',
    'Propinas',
    'Pagos de Terceros',
    'Mesada',
  ];

  static const Map<String, List<Map<String, String>>> expenseCategories = {
    'indispensable': [
      {'key': 'arriendo_dividendo', 'display_name': 'Arriendo / Dividendo'},
      {'key': 'luz', 'display_name': 'Luz'},
      {'key': 'agua', 'display_name': 'Agua'},
      {'key': 'gas', 'display_name': 'Gas'},
      {'key': 'internet', 'display_name': 'Internet'},
      {'key': 'telefono', 'display_name': 'Telefono'},
      {'key': 'transporte', 'display_name': 'Transporte'},
      {'key': 'alimentacion', 'display_name': 'Alimentacion'},
    ],
    'recurrente': [
      {'key': 'tarjeta_credito', 'display_name': 'Tarjeta de Credito'},
      {'key': 'prestamo', 'display_name': 'Prestamo'},
      {'key': 'seguro', 'display_name': 'Seguro'},
      {'key': 'suscripcion', 'display_name': 'Suscripcion'},
      {'key': 'educacion', 'display_name': 'Educacion'},
      {'key': 'salud', 'display_name': 'Salud'},
    ],
    'extraordinario': [
      {'key': 'compras', 'display_name': 'Compras'},
      {'key': 'salidas', 'display_name': 'Salidas'},
      {'key': 'regalos', 'display_name': 'Regalos'},
      {'key': 'medico', 'display_name': 'Medico'},
      {'key': 'viajes', 'display_name': 'Viajes'},
      {'key': 'mascotas', 'display_name': 'Mascotas'},
      {'key': 'otros', 'display_name': 'Otros'},
    ],
  };

  static const String defaultPaymentMethod = 'Efectivo';
}
