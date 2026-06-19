import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/expense_sections.dart';
import '../../data/models/transaction_item.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';

class ExpandableTransactionCard extends StatefulWidget {
  final TransactionItem transaction;
  final int year;
  final int month;
  final VoidCallback? onAddChild;
  final VoidCallback? onEdit;

  const ExpandableTransactionCard({
    super.key,
    required this.transaction,
    required this.year,
    required this.month,
    this.onAddChild,
    this.onEdit,
  });

  @override
  State<ExpandableTransactionCard> createState() => _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends State<ExpandableTransactionCard> {
  bool _isExpanded = false;

  IconData _getCategoryIcon(String category) {
    const icons = {
      'sueldo': Icons.work_outline_rounded,
      'ventas': Icons.sell_outlined,
      'pagos_tercero': Icons.handshake_outlined,
      'arriendo_dividendo': Icons.home_outlined,
      'luz': Icons.lightbulb_outline,
      'agua': Icons.water_drop_outlined,
      'gas': Icons.local_fire_department_outlined,
      'internet': Icons.wifi_outlined,
      'tarjeta_credito': Icons.credit_card_outlined,
      'prestamo': Icons.account_balance_outlined,
      'seguro': Icons.shield_outlined,
      'suscripcion': Icons.subscriptions_outlined,
      'compras': Icons.shopping_bag_outlined,
      'salidas': Icons.restaurant_outlined,
      'regalos': Icons.card_giftcard_outlined,
      'medico': Icons.local_hospital_outlined,
    };
    return icons[category] ?? Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.transaction;
    final isIncome = item.type == 'income';
    final accentColor = isIncome ? AppTheme.income : AppTheme.cost;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.black.withValues(alpha: 0.06);

    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.cost,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar eliminacion'),
            content: const Text('Estas seguro de que deseas eliminar este registro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar',
                    style: TextStyle(color: AppTheme.cost, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (item.id != null) {
          context.read<FinanceBloc>().add(
                DeleteTransaction(id: item.id!, year: widget.year, month: widget.month),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaccion eliminada')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: item.hasChildren
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : widget.onEdit,
              onLongPress: !isIncome ? widget.onAddChild : null,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getCategoryIcon(item.category), color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                isIncome
                                    ? item.category
                                    : ExpenseSections.getCategoryDisplayName(item.category),
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.labelLarge?.color,
                                    fontSize: 12),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4, height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white30 : Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item.date.day}/${item.date.month}',
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.labelLarge?.color,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (item.hasChildren)
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).textTheme.labelLarge?.color,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _isExpanded && item.hasChildren
                  ? Column(
                      children: [
                        Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                            height: 1, indent: 16, endIndent: 16),
                        ...item.children.map((child) => _buildChildRow(child, isDark)),
                        if (!isIncome)
                          InkWell(
                            onTap: widget.onAddChild,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 56, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.add, size: 16, color: AppTheme.primary),
                                  SizedBox(width: 8),
                                  Text('Agregar sub-item',
                                      style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildRow(TransactionItem child, bool isDark) {
    return Dismissible(
      key: Key('child_${child.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppTheme.cost.withValues(alpha: 0.3),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Confirmar eliminacion'),
            content: Text('Eliminar "${child.description}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('Cancelar',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar',
                    style: TextStyle(color: AppTheme.cost, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (child.id != null) {
          context.read<FinanceBloc>().add(
                DeleteTransaction(id: child.id!, year: widget.year, month: widget.month),
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sub-item eliminado')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                child.description,
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13),
              ),
            ),
            Text(
              CurrencyFormatter.format(child.amount),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
