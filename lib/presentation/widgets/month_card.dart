import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/monthly_summary.dart';

class MonthCard extends StatelessWidget {
  final MonthlySummary summary;
  final VoidCallback onTap;

  const MonthCard({super.key, required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(summary.month);
    final isDeficit = summary.isDeficit;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthName ${summary.year}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isDeficit ? AppTheme.cost : AppTheme.savings)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    isDeficit ? 'Deficit' : 'Ahorro',
                    style: TextStyle(
                      color: isDeficit ? AppTheme.cost : AppTheme.savings,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ingresos', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      CurrencyFormatter.format(summary.totalIncome),
                      style: const TextStyle(color: AppTheme.income, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Costos', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      CurrencyFormatter.format(summary.totalCost),
                      style: const TextStyle(color: AppTheme.cost, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDeficit ? 'Deficit Mensual' : 'Ahorro Mensual',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(summary.totalIncome)} - ${CurrencyFormatter.format(summary.totalCost)} = ${CurrencyFormatter.format(summary.balance)}',
                      style: TextStyle(
                        color: isDeficit ? AppTheme.cost : AppTheme.savings,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver detalle',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
