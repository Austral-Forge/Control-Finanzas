import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final String? title;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = totalBalance < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.12),
            AppTheme.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'BALANCE GENERAL DE AHORROS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(totalBalance),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: isDeficit ? AppTheme.cost : AppTheme.income,
                      fontSize: 36,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                isDeficit ? 'Déficit acumulado' : 'Ahorro Neto',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDeficit
                          ? AppTheme.cost.withOpacity(0.7)
                          : AppTheme.income.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
