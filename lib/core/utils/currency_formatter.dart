import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
      decimalDigits: 0,
    );
    if (amount % 1 == 0) {
      return formatter.format(amount);
    } else {
      return NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 2,
      ).format(amount);
    }
  }

  static String getMonthName(int month) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
