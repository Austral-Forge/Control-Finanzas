import '../../core/constants/institution_catalog.dart';
import '../../domain/services/bank_sync_service.dart';
import '../models/bank_connection.dart';

/// Implementacion por defecto sin proveedor externo: el usuario registra sus
/// movimientos con el medio de pago de cada institucion. Reemplazar por una
/// implementacion real (Fintoc/Floid) cuando exista backend y credenciales.
class ManualBankSyncService implements BankSyncService {
  @override
  String get providerName => BankConnection.syncModeManual;

  @override
  bool get isAvailable => false;

  @override
  Future<BankSyncResult> linkAccount(Institution institution) async {
    return const BankSyncResult(
      success: true,
      message:
          'Vinculo manual creado. Registra tus movimientos con el medio de pago de la institucion.',
    );
  }

  @override
  Future<BankSyncResult> syncTransactions(
    BankConnection connection, {
    DateTime? since,
  }) async {
    return const BankSyncResult(
      success: false,
      message: 'La sincronizacion automatica estara disponible proximamente.',
    );
  }
}
