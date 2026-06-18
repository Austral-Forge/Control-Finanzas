import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/expense_sections.dart';
import '../../data/models/transaction_item.dart';
import '../widgets/expandable_transaction_card.dart';

class DetailScreen extends StatefulWidget {
  final int year;
  final int month;

  const DetailScreen({super.key, required this.year, required this.month});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(
          LoadMonthDetails(year: widget.year, month: widget.month),
        );
  }

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(widget.month);

    return Scaffold(
      appBar: AppBar(
        title: Text('$monthName ${widget.year}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            context.read<FinanceBloc>().add(LoadFinanceSummaries());
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoaded) {
            if (state.isDetailsLoading || state.selectedMonthTransactions == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }

            final transactions = state.selectedMonthTransactions!;
            return _buildSectionsView(transactions);
          } else if (state is FinanceError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        },
      ),
    );
  }

  Widget _buildSectionsView(List<TransactionItem> transactions) {
    final incomes = transactions.where((t) => t.type == 'income').toList();
    final costs = transactions.where((t) => t.type == 'cost').toList();

    final totalIncome = incomes.fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalCost = costs.fold<double>(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalCost;

    // Group costs by expense section
    final indispensables = costs
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.indispensable)
        .toList();
    final recurrentes = costs
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.recurrente)
        .toList();
    final extraordinarios = costs
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.extraordinario)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSummary(totalIncome, totalCost, balance),
          const SizedBox(height: 24),
          _buildSection(
            'Ingresos',
            Icons.trending_up,
            AppTheme.income,
            incomes,
            totalIncome,
          ),
          if (indispensables.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              'Gastos Indispensables',
              Icons.home_outlined,
              AppTheme.cost,
              indispensables,
              indispensables.fold(0.0, (s, t) => s + t.amount),
            ),
          ],
          if (recurrentes.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              'Gastos Recurrentes',
              Icons.repeat,
              AppTheme.primary,
              recurrentes,
              recurrentes.fold(0.0, (s, t) => s + t.amount),
            ),
          ],
          if (extraordinarios.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              'Gastos Extraordinarios',
              Icons.star_outline,
              AppTheme.savings,
              extraordinarios,
              extraordinarios.fold(0.0, (s, t) => s + t.amount),
            ),
          ],
          if (costs.isEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              'Egresos',
              Icons.trending_down,
              AppTheme.cost,
              [],
              0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSummary(double income, double cost, double balance) {
    final isDeficit = balance < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('Ingresos', income, AppTheme.income),
              Container(width: 1, height: 35, color: Colors.white12),
              _buildSummaryColumn('Egresos', cost, AppTheme.cost),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeficit ? 'Déficit del Mes' : 'Ahorro del Mes',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                CurrencyFormatter.format(balance),
                style: TextStyle(
                  color: isDeficit ? AppTheme.cost : AppTheme.savings,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(value),
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<TransactionItem> items,
    double subtotal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${items.length})',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
            Text(
              CurrencyFormatter.format(subtotal),
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Sin registros',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6)),
            ),
          )
        else
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpandableTransactionCard(
                transaction: item,
                year: widget.year,
                month: widget.month,
                onAddChild: item.type == 'cost'
                    ? () => _showAddChildDialog(context, item)
                    : null,
              ),
            );
          }),
      ],
    );
  }

  void _showAddChildDialog(BuildContext context, TransactionItem parent) {
    double amount = 0;
    String description = '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Sub-item de "${parent.description}"',
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ej: Interés, Comisión, Seguro desgravamen',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa una descripción' : null,
                  onSaved: (v) => description = v!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa un monto';
                    if (double.tryParse(v) == null || double.parse(v) <= 0) {
                      return 'Monto mayor a 0';
                    }
                    return null;
                  },
                  onSaved: (v) => amount = double.parse(v!),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final child = TransactionItem(
                          type: 'cost',
                          category: parent.category,
                          amount: amount,
                          description: description,
                          date: parent.date,
                          parentId: parent.id,
                        );
                        context.read<FinanceBloc>().add(
                              AddChildTransaction(
                                child: child,
                                year: widget.year,
                                month: widget.month,
                              ),
                            );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Guardar Sub-item',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
