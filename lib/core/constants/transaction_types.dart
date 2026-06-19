/// Tipos de transacción persistidos en la base de datos.
///
/// Se modelan como constantes de cadena (en lugar de un enum) porque el valor
/// se almacena directamente en la columna `type` de la tabla `transactions`.
class TransactionType {
  const TransactionType._();

  static const String income = 'income';
  static const String cost = 'cost';

  static bool isIncome(String type) => type == income;
  static bool isCost(String type) => type == cost;
}
