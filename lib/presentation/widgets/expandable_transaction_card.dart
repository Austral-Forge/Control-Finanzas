import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/expense_category_lookup.dart';
import '../../core/constants/transaction_types.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_item.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';

class ExpandableTransactionCard extends StatefulWidget {
  final TransactionItem transaction;
  final int year;
  final int month;
  final ExpenseCategoryLookup categoryLookup;
  final VoidCallback? onAddChild;
  final VoidCallback? onEdit;

  const ExpandableTransactionCard({
    super.key,
    required this.transaction,
    required this.year,
    required this.month,
    required this.categoryLookup,
    this.onAddChild,
    this.onEdit,
  });

  @override
  State<ExpandableTransactionCard> createState() =>
      _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends State<ExpandableTransactionCard> {
  static const _categoryIcons = <String, IconData>{
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

  bool _isExpanded = false;

  IconData _iconFor(String category) =>
      _categoryIcons[category] ?? Icons.category_outlined;

  Future<bool> _confirmDelete(String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminacion'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(
                    color: AppTheme.cost, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _delete(int id, String confirmationMessage) {
    context.read<FinanceBloc>().add(
          DeleteTransaction(id: id, year: widget.year, month: widget.month),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(confirmationMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.transaction;
    final isIncome = TransactionType.isIncome(item.type);
    final accentColor = isIncome ? AppTheme.income : AppTheme.cost;

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
      confirmDismiss: (_) =>
          _confirmDelete('Estas seguro de que deseas eliminar este registro?'),
      onDismissed: (_) {
        if (item.id != null) _delete(item.id!, 'Transaccion eliminada');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: item.hasChildren
                  ? () => setState(() => _isExpanded = !_isExpanded)
                  : widget.onEdit,
              onLongPress: isIncome ? null : widget.onAddChild,
              borderRadius: BorderRadius.circular(18),
              child: _buildMainRow(item, isIncome, accentColor),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: _isExpanded && item.hasChildren
                  ? _buildChildrenSection(item, isIncome)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainRow(TransactionItem item, bool isIncome, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(item.category), color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      isIncome
                          ? item.category
                          : widget.categoryLookup.displayNameOf(item.category),
                      style: TextStyle(
                          color: context.mutedTextColor, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.isDark ? Colors.white30 : Colors.black26,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${item.date.day}/${item.date.month}',
                        style: TextStyle(
                            color: context.mutedTextColor, fontSize: 12)),
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
                    fontSize: 16),
              ),
              if (item.hasChildren)
                Icon(_isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: context.mutedTextColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection(TransactionItem item, bool isIncome) {
    return Column(
      children: [
        Divider(
            color: context.dividerColor, height: 1, indent: 16, endIndent: 16),
        ...item.children.map(_buildChildRow),
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
    );
  }

  Widget _buildChildRow(TransactionItem child) {
    return Dismissible(
      key: Key('child_${child.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppTheme.cost.withValues(alpha: 0.3),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
      ),
      confirmDismiss: (_) => _confirmDelete('Eliminar "${child.description}"?'),
      onDismissed: (_) {
        if (child.id != null) _delete(child.id!, 'Sub-item eliminado');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: (context.isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(child.description,
                  style: TextStyle(
                      color: context.secondaryTextColor, fontSize: 13)),
            ),
            Text(
              CurrencyFormatter.format(child.amount),
              style: TextStyle(
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
