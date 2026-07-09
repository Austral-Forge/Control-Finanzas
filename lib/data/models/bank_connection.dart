/// Vínculo del usuario con un banco o casa comercial. Al conectar se asocia un
/// medio de pago con el nombre de la institución: los movimientos registrados
/// con ese medio permiten medir los ingresos y gastos de cada institución.
///
/// El campo [syncMode] deja la puerta abierta a sincronización automática vía
/// open banking (p.ej. Fintoc/Floid): hoy siempre es `manual`.
class BankConnection {
  static const String syncModeManual = 'manual';

  final int? id;
  final String institutionKey;
  final String institutionName;
  final String institutionType; // 'banco' | 'casa_comercial'
  final int? paymentMethodId;
  final String syncMode;
  final String connectedAt; // ISO-8601

  BankConnection({
    this.id,
    required this.institutionKey,
    required this.institutionName,
    required this.institutionType,
    this.paymentMethodId,
    this.syncMode = syncModeManual,
    required this.connectedAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'institution_key': institutionKey,
        'institution_name': institutionName,
        'institution_type': institutionType,
        'payment_method_id': paymentMethodId,
        'sync_mode': syncMode,
        'connected_at': connectedAt,
      };

  factory BankConnection.fromMap(Map<String, dynamic> map) => BankConnection(
        id: map['id'] as int?,
        institutionKey: map['institution_key'] as String,
        institutionName: map['institution_name'] as String,
        institutionType: map['institution_type'] as String,
        paymentMethodId: map['payment_method_id'] as int?,
        syncMode: map['sync_mode'] as String? ?? syncModeManual,
        connectedAt: map['connected_at'] as String,
      );
}
