import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';

class SavingsConfirmationSheet extends StatefulWidget {
  final double calculatedSavings;
  final int year;
  final int month;
  final void Function(double confirmedAmount) onConfirm;

  const SavingsConfirmationSheet({
    super.key,
    required this.calculatedSavings,
    required this.year,
    required this.month,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required double calculatedSavings,
    required int year,
    required int month,
    required void Function(double confirmedAmount) onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavingsConfirmationSheet(
        calculatedSavings: calculatedSavings,
        year: year,
        month: month,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SavingsConfirmationSheet> createState() =>
      _SavingsConfirmationSheetState();
}

class _SavingsConfirmationSheetState extends State<SavingsConfirmationSheet> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.calculatedSavings.toStringAsFixed(
          widget.calculatedSavings.truncateToDouble() == widget.calculatedSavings
              ? 0
              : 2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(widget.month);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.mutedTextColor?.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.savings.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.savings_outlined,
                      color: AppTheme.savings, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Confirmar Ahorro de $monthName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Tu ahorro acumulado calculado es:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(widget.calculatedSavings),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.savings,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              'Si utilizaste parte de tus ahorros, ajusta el monto real disponible:',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: context.mutedTextColor),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto confirmado',
                prefixText: '\$ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingresa un monto';
                final parsed = double.tryParse(value);
                if (parsed == null || parsed < 0) return 'Monto no valido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Confirmar Ahorro'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.savings,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    Navigator.pop(context);
    widget.onConfirm(amount);
  }
}
