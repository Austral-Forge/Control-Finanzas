import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_item.freezed.dart';
part 'transaction_item.g.dart';

@freezed
class TransactionItem with _$TransactionItem {
  const factory TransactionItem({
    int? id,
    required String type, // 'income' o 'cost'
    required String category, // 'sueldo', 'ventas', 'pagos_tercero' para ingresos; 'tarjetas', 'prestamos', 'compras', 'pagos_basicos', 'otros' para costos.
    required double amount,
    required String description,
    required DateTime date,
  }) = _TransactionItem;

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      _$TransactionItemFromJson(json);
}
