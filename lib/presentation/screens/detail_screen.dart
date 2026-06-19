import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_state.dart';
import '../../core/constants/transaction_types.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/expense_sections.dart';
import '../../core/constants/expense_category_lookup.dart';
import '../../data/models/transaction_item.dart';
import '../widgets/expandable_transaction_card.dart';
import '../widgets/transaction_form_sheet.dart';

enum TransactionFilter { all, income, cost }

class DetailScreen extends StatefulWidget {
  final int year;
  final int month;

  const DetailScreen({super.key, required this.year, required this.month});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  TransactionFilter _filter = TransactionFilter.all;
  String? _selectedCategory;
  late ExpenseCategoryLookup _categoryLookup;

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

    final settingsState = context.watch<SettingsBloc>().state;
    _categoryLookup = ExpenseCategoryLookup(
      settingsState is SettingsLoaded
          ? settingsState.expenseCategories
          : const [],
    );

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
            if (state.isDetailsLoading ||
                state.selectedMonthTransactions == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            return _buildSectionsView(state.selectedMonthTransactions!);
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

  List<TransactionItem> _applyFilters(List<TransactionItem> transactions) {
    return transactions.where((t) {
      if (_filter == TransactionFilter.income &&
          !TransactionType.isIncome(t.type)) {
        return false;
      }
      if (_filter == TransactionFilter.cost && !TransactionType.isCost(t.type)) {
        return false;
      }
      if (_selectedCategory != null && t.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TransactionItem> _costsBySection(
    List<TransactionItem> costs,
    ExpenseSection section,
  ) {
    return costs
        .where((t) => _categoryLookup.sectionOf(t.category) == section)
        .toList();
  }

  double _sum(List<TransactionItem> items) =>
      items.fold(0.0, (sum, t) => sum + t.amount);

  Widget _buildSectionsView(List<TransactionItem> transactions) {
    final incomes =
        transactions.where((t) => TransactionType.isIncome(t.type)).toList();
    final costs =
        transactions.where((t) => TransactionType.isCost(t.type)).toList();

    final totalIncome = _sum(incomes);
    final totalCost = _sum(costs);

    final filtered = _applyFilters(transactions);
    final filteredIncomes =
        filtered.where((t) => TransactionType.isIncome(t.type)).toList();
    final filteredCosts =
        filtered.where((t) => TransactionType.isCost(t.type)).toList();

    final indispensables =
        _costsBySection(filteredCosts, ExpenseSection.indispensable);
    final recurrentes =
        _costsBySection(filteredCosts, ExpenseSection.recurrente);
    final extraordinarios =
        _costsBySection(filteredCosts, ExpenseSection.extraordinario);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSummary(totalIncome, totalCost),
          const SizedBox(height: 16),
          _buildKpiCharts(costs, totalIncome, totalCost),
          const SizedBox(height: 16),
          _buildFilterBar(transactions),
          const SizedBox(height: 16),
          if (_filter != TransactionFilter.cost)
            _buildSection('Ingresos', Icons.trending_up, AppTheme.income,
                filteredIncomes, _sum(filteredIncomes)),
          if (_filter != TransactionFilter.income) ...[
            if (indispensables.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Indispensables', Icons.home_outlined,
                  AppTheme.cost, indispensables, _sum(indispensables)),
            ],
            if (recurrentes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Recurrentes', Icons.repeat, AppTheme.primary,
                  recurrentes, _sum(recurrentes)),
            ],
            if (extraordinarios.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Extraordinarios', Icons.star_outline,
                  AppTheme.savings, extraordinarios, _sum(extraordinarios)),
            ],
            if (filteredCosts.isEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Egresos', Icons.trending_down, AppTheme.cost, [], 0),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<TransactionItem> transactions) {
    final categories = transactions.map((t) => t.category).toSet().toList()
      ..sort();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Row(
            children: [
              _buildFilterChip('Todos', TransactionFilter.all, null),
              _buildFilterChip('Ingresos', TransactionFilter.income, AppTheme.income),
              _buildFilterChip('Egresos', TransactionFilter.cost, AppTheme.cost),
            ],
          ),
        ),
        if (_selectedCategory != null || categories.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: const Text('Todas', style: TextStyle(fontSize: 12)),
                      selected: false,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_categoryLookup.displayNameOf(cat),
                          style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      onSelected: (_) => setState(
                          () => _selectedCategory = isSelected ? null : cat),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(
      String label, TransactionFilter filter, Color? activeColor) {
    final isActive = _filter == filter;
    final color = activeColor ?? AppTheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _filter = filter;
          _selectedCategory = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? color : context.secondaryTextColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCharts(
      List<TransactionItem> costs, double totalIncome, double totalCost) {
    if (costs.isEmpty && totalIncome == 0) return const SizedBox();

    final categoryTotals = <String, double>{};
    for (final c in costs) {
      categoryTotals[c.category] = (categoryTotals[c.category] ?? 0) + c.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final savings = totalIncome - totalCost;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribucion de Gastos', style: context.textTheme.titleMedium),
          const SizedBox(height: 16),
          if (costs.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(child: _buildPieChart(sortedCategories, totalCost)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPieLegend(sortedCategories)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildKpiTile(
                  'Tasa Ahorro',
                  totalIncome > 0
                      ? '${(savings / totalIncome * 100).toStringAsFixed(1)}%'
                      : '0%',
                  savings >= 0 ? AppTheme.income : AppTheme.cost,
                  Icons.savings_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  'Mayor Gasto',
                  sortedCategories.isNotEmpty
                      ? _categoryLookup
                          .displayNameOf(sortedCategories.first.key)
                      : 'N/A',
                  AppTheme.cost,
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiTile('Categorias', '${categoryTotals.length}',
                    AppTheme.primary, Icons.category_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  'Promedio/Gasto',
                  costs.isNotEmpty
                      ? CurrencyFormatter.format(totalCost / costs.length)
                      : '\$0',
                  AppTheme.savings,
                  Icons.calculate_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const List<Color> _pieColors = [
    AppTheme.cost,
    AppTheme.primary,
    AppTheme.savings,
    AppTheme.income,
    Color(0xFFFF6B6B),
    Color(0xFFFFA94D),
    Color(0xFFFFD43B),
    Color(0xFF69DB7C),
    Color(0xFF63E6BE),
    Color(0xFF66D9EF),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
  ];

  Widget _buildPieChart(
      List<MapEntry<String, double>> sortedCategories, double totalCost) {
    return PieChart(
      PieChartData(
        sections: sortedCategories.asMap().entries.map((entry) {
          final value = entry.value.value;
          final percentage = totalCost > 0 ? value / totalCost * 100 : 0;
          return PieChartSectionData(
            value: value,
            color: _pieColors[entry.key % _pieColors.length],
            radius: 50,
            title: '${percentage.toStringAsFixed(0)}%',
            titleStyle: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          );
        }).toList(),
        centerSpaceRadius: 35,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPieLegend(List<MapEntry<String, double>> sortedCategories) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.take(6).toList().asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _pieColors[entry.key % _pieColors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _categoryLookup.displayNameOf(entry.value.key),
                  style: TextStyle(
                      fontSize: 11, color: context.secondaryTextColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: context.mutedTextColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary(double income, double cost) {
    final balance = income - cost;
    final isDeficit = balance < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('Ingresos', income, AppTheme.income),
              Container(width: 1, height: 35, color: context.dividerColor),
              _buildSummaryColumn('Egresos', cost, AppTheme.cost),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: context.dividerColor, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeficit ? 'Deficit del Mes' : 'Ahorro del Mes',
                style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w500),
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
        Text(label,
            style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(value),
          style:
              TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16),
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
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(width: 8),
                Text('(${items.length})',
                    style:
                        TextStyle(color: context.mutedTextColor, fontSize: 13)),
              ],
            ),
            Text(CurrencyFormatter.format(subtotal),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Sin registros',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.mutedTextColor?.withValues(alpha: 0.6)),
            ),
          )
        else
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ExpandableTransactionCard(
                  transaction: item,
                  year: widget.year,
                  month: widget.month,
                  categoryLookup: _categoryLookup,
                  onEdit: () => _editTransaction(item),
                  onAddChild: TransactionType.isCost(item.type)
                      ? () => _showAddChildDialog(context, item)
                      : null,
                ),
              )),
      ],
    );
  }

  void _editTransaction(TransactionItem transaction) {
    TransactionFormSheet.show(
      context,
      initial: transaction,
      onSubmit: (updated) {
        context.read<FinanceBloc>().add(UpdateTransaction(
              transaction: updated,
              year: widget.year,
              month: widget.month,
            ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaccion actualizada')),
        );
      },
    );
  }

  void _showAddChildDialog(BuildContext context, TransactionItem parent) {
    double amount = 0;
    String description = '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                        style: context.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ej: Interes, Comision, Seguro desgravamen',
                  style: TextStyle(color: context.mutedTextColor, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa una descripcion'
                      : null,
                  onSaved: (v) => description = v!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monto (\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa un monto';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) return 'Monto mayor a 0';
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
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final child = TransactionItem(
                          type: TransactionType.cost,
                          category: parent.category,
                          amount: amount,
                          description: description,
                          date: parent.date,
                          parentId: parent.id,
                        );
                        context.read<FinanceBloc>().add(AddChildTransaction(
                              child: child,
                              year: widget.year,
                              month: widget.month,
                            ));
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sub-item agregado')),
                        );
                      }
                    },
                    child: const Text(
                      'Guardar Sub-item',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
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
