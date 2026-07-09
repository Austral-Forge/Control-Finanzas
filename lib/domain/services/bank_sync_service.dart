import '../../core/constants/institution_catalog.dart';
import '../../data/models/bank_connection.dart';
import '../../data/models/transaction_item.dart';

/// Puerto de sincronizacion con proveedores de open banking (Fintoc, Floid,
/// etc.). La app funciona hoy en modo manual: para integrar un proveedor real
/// basta implementar esta interfaz e inyectarla en `SettingsBloc`, sin tocar
/// la UI ni la base de datos.
abstract class BankSyncService {
  /// Identificador del proveedor ('manual', 'fintoc', 'floid', ...).
  String get providerName;

  /// `true` cuando hay un proveedor real configurado y con credenciales.
  bool get isAvailable;

  /// Inicia el vinculo de la institucion en el proveedor externo
  /// (tipicamente abre el widget de autenticacion del proveedor).
  Future<BankSyncResult> linkAccount(Institution institution);

  /// Trae los movimientos nuevos de una conexion desde [since].
  Future<BankSyncResult> syncTransactions(
    BankConnection connection, {
    DateTime? since,
  });
}

class BankSyncResult {
  final bool success;
  final String message;
  final List<TransactionItem> transactions;

  const BankSyncResult({
    required this.success,
    required this.message,
    this.transactions = const [],
  });
}
