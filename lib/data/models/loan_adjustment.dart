import 'installment.dart';

/// Efecto neto de todos los préstamos (cuotas) que vencen en un mes
/// específico, sin importar si ya se marcaron como pagadas o no. A
/// diferencia de [Installment.dueAmountForMonth] (que solo mira cuotas
/// pendientes, útil para proyectar el futuro), esto reconstruye el
/// calendario completo para poder reflejar tambien meses ya ocurridos.
class LoanAdjustment {
  /// Cuotas que me pagan ese mes (dinero que presté).
  final double incoming;

  /// Cuotas que pago ese mes (compras, deudas o dinero que me prestaron).
  final double outgoing;

  const LoanAdjustment({this.incoming = 0, this.outgoing = 0});

  static const empty = LoanAdjustment();

  /// Balance neto: positivo si el mes recibe más de lo que paga en cuotas.
  double get net => incoming - outgoing;

  bool get isZero => incoming == 0 && outgoing == 0;

  static LoanAdjustment forMonth(
      List<Installment> installments, int year, int month) {
    double incoming = 0;
    double outgoing = 0;
    for (final inst in installments) {
      for (final entry in inst.schedule()) {
        if (entry.year != year || entry.month != month) continue;
        if (inst.isIncoming) {
          incoming += entry.amount;
        } else {
          outgoing += entry.amount;
        }
      }
    }
    return LoanAdjustment(incoming: incoming, outgoing: outgoing);
  }
}
