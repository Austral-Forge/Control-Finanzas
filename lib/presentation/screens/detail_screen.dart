import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/expense_sections.dart';
import '../../data/models/transaction_item.dart';
import '../widgets/expandable_transaction_card.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            return _buildSectionsView(transactions, isDark);
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
    var filtered = transactions;

    if (_filter == TransactionFilter.income) {
      filtered = filtered.where((t) => t.type == 'income').toList();
    } else if (_filter == TransactionFilter.cost) {
      filtered = filtered.where((t) => t.type == 'cost').toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((t) => t.category == _selectedCategory).toList();
    }

    return filtered;
  }

  Widget _buildSectionsView(List<TransactionItem> transactions, bool isDark) {
    final incomes = transactions.where((t) => t.type == 'income').toList();
    final costs = transactions.where((t) => t.type == 'cost').toList();

    final totalIncome = incomes.fold<double>(0.0, (sum, t) => sum + t.amount);
    final totalCost = costs.fold<double>(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalCost;

    final filteredTransactions = _applyFilters(transactions);

    final filteredIncomes = filteredTransactions.where((t) => t.type == 'income').toList();
    final filteredCosts = filteredTransactions.where((t) => t.type == 'cost').toList();

    final indispensables = filteredCosts
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.indispensable)
        .toList();
    final recurrentes = filteredCosts
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.recurrente)
        .toList();
    final extraordinarios = filteredCosts
        .where((t) => ExpenseSections.getSection(t.category) == ExpenseSection.extraordinario)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSummary(totalIncome, totalCost, balance, isDark),
          const SizedBox(height: 16),
          _buildKpiCharts(costs, totalIncome, totalCost, isDark),
          const SizedBox(height: 16),
          _buildFilterBar(transactions, isDark),
          const SizedBox(height: 16),
          if (_filter != TransactionFilter.cost)
            _buildSection('Ingresos', Icons.trending_up, AppTheme.income, filteredIncomes,
                filteredIncomes.fold(0.0, (s, t) => s + t.amount)),
          if (_filter != TransactionFilter.income) ...[
            if (indispensables.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Indispensables', Icons.home_outlined, AppTheme.cost,
                  indispensables, indispensables.fold(0.0, (s, t) => s + t.amount)),
            ],
            if (recurrentes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Recurrentes', Icons.repeat, AppTheme.primary, recurrentes,
                  recurrentes.fold(0.0, (s, t) => s + t.amount)),
            ],
            if (extraordinarios.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSection('Gastos Extraordinarios', Icons.star_outline, AppTheme.savings,
                  extraordinarios, extraordinarios.fold(0.0, (s, t) => s + t.amount)),
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

  Widget _buildFilterBar(List<TransactionItem> transactions, bool isDark) {
    final surfColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    final categories = transactions.map((t) => t.category).toSet().toList()..sort();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: surfColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
                      onSelected: (_) => setState(() => _selectedCategory = null),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ...categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final displayName = ExpenseSections.getCategoryDisplayName(cat);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(displayName, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.primary,
                      onSelected: (_) {
                        setState(() => _selectedCategory = isSelected ? null : cat);
                      },
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

  Widget _buildFilterChip(String label, TransactionFilter filter, Color? activeColor) {
    final isActive = _filter == filter;
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
            color: isActive ? (activeColor ?? AppTheme.primary).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? (activeColor ?? AppTheme.primary) : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCharts(List<TransactionItem> costs, double totalIncome, double totalCost, bool isDark) {
    if (costs.isEmpty && totalIncome == 0) return const SizedBox();

    final surfColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    final categoryTotals = <String, double>{};
    for (final c in costs) {
      categoryTotals[c.category] = (categoryTotals[c.category] ?? 0) + c.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final pieColors = [
      AppTheme.cost,
      AppTheme.primary,
      AppTheme.savings,
      AppTheme.income,
      const Color(0xFFFF6B6B),
      const Color(0xFFFFA94D),
      const Color(0xFFFFD43B),
      const Color(0xFF69DB7C),
      const Color(0xFF63E6BE),
      const Color(0xFF66D9EF),
      const Color(0xFFA78BFA),
      const Color(0xFFF472B6),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribucion de Gastos',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          if (costs.isNotEmpty) ...[
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sortedCategories.asMap().entries.map((entry) {
                          final i = entry.key;
                          final cat = entry.value;
                          final percentage = totalCost > 0 ? (cat.value / totalCost * 100) : 0;
                          return PieChartSectionData(
                            value: cat.value,
                            color: pieColors[i % pieColors.length],
                            radius: 50,
                            title: '${percentage.toStringAsFixed(0)}%',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 35,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedCategories.take(6).toList().asMap().entries.map((entry) {
                        final i = entry.key;
                        final cat = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: pieColors[i % pieColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ExpenseSections.getCategoryDisplayName(cat.key),
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
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
                      ? '${((totalIncome - totalCost) / totalIncome * 100).toStringAsFixed(1)}%'
                      : '0%',
                  (totalIncome - totalCost) >= 0 ? AppTheme.income : AppTheme.cost,
                  Icons.savings_outlined,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiTile(
                  'Mayor Gasto',
                  sortedCategories.isNotEmpty
                      ? ExpenseSections.getCategoryDisplayName(sortedCategories.first.key)
                      : 'N/A',
                  AppTheme.cost,
                  Icons.trending_up,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiTile(
                  'Categorias',
                  '${categoryTotals.length}',
                  AppTheme.primary,
                  Icons.category_outlined,
                  isDark,
                ),
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
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile(String label, String value, Color color, IconData icon, bool isDark) {
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
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary(double income, double cost, double balance, bool isDark) {
    final isDeficit = balance < 0;
    final surfColor = Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryColumn('Ingresos', income, AppTheme.income),
              Container(width: 1, height: 35, color: isDark ? Colors.white12 : Colors.black12),
              _buildSummaryColumn('Egresos', cost, AppTheme.cost),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeficit ? 'Deficit del Mes' : 'Ahorro del Mes',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
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
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${items.length})',
                  style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color, fontSize: 13),
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Sin registros',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color?.withValues(alpha: 0.6)),
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
                onEdit: () => _showEditTransactionDialog(context, item),
                onAddChild: item.type == 'cost'
                    ? () => _showAddChildDialog(context, item)
                    : null,
              ),
            );
          }),
      ],
    );
  }

  void _showEditTransactionDialog(BuildContext context, TransactionItem transaction) {
    final formKey = GlobalKey<FormState>();
    double amount = transaction.amount;
    String description = transaction.description;
    DateTime date = transaction.date;
    String category = transaction.category;
    int? incomeSourceId = transaction.incomeSourceId;
    int? paymentMethodId = transaction.paymentMethodId;

    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is! SettingsLoaded) return;

    final incomeSources = settingsState.incomeSources;
    final paymentMethods = settingsState.paymentMethods;
    final expenseCategories = settingsState.expenseCategories;
    final isIncome = transaction.type == 'income';

    final amountController = TextEditingController(text: amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2));
    final descController = TextEditingController(text: description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Editar Transaccion',
                              style: Theme.of(ctx).textTheme.headlineMedium),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isIncome ? AppTheme.income : AppTheme.cost).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isIncome ? 'Ingreso' : 'Egreso',
                          style: TextStyle(
                            color: isIncome ? AppTheme.income : AppTheme.cost,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: amountController,
                        style: const TextStyle(fontSize: 18),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto (\$)',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa un monto';
                          if (double.tryParse(value) == null || double.parse(value) <= 0) {
                            return 'Ingresa un monto mayor a 0';
                          }
                          return null;
                        },
                        onSaved: (value) => amount = double.parse(value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion / Concepto',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Ingresa una descripcion';
                          return null;
                        },
                        onSaved: (value) => description = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      if (isIncome && incomeSources.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: incomeSourceId,
                          decoration: const InputDecoration(
                            labelText: 'Fuente de Ingreso',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          items: incomeSources.map((src) {
                            return DropdownMenuItem<int>(value: src.id, child: Text(src.name));
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              incomeSourceId = value;
                              category = incomeSources.firstWhere((s) => s.id == value).name;
                            });
                          },
                        ),
                      if (!isIncome && expenseCategories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Categoria de Gasto',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: expenseCategories.map((cat) {
                            final sectionLabel = ExpenseSections.getSectionDisplayName(
                              ExpenseSections.getSection(cat.key),
                            );
                            return DropdownMenuItem<String>(
                              value: cat.key,
                              child: Text('${cat.displayName} ($sectionLabel)'),
                            );
                          }).toList(),
                          onChanged: (value) => setModalState(() => category = value!),
                        ),
                      if (!isIncome && paymentMethods.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: paymentMethodId,
                          decoration: const InputDecoration(
                            labelText: 'Medio de Pago',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int>(value: null, child: Text('Sin especificar')),
                            ...paymentMethods.map((pm) {
                              return DropdownMenuItem<int>(value: pm.id, child: Text(pm.name));
                            }),
                          ],
                          onChanged: (value) => setModalState(() => paymentMethodId = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: ctx,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) setModalState(() => date = pickedDate);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(ctx).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(ctx).brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 20, color: Theme.of(ctx).textTheme.bodyMedium?.color),
                                  const SizedBox(width: 12),
                                  Text('Fecha: ${date.day}/${date.month}/${date.year}',
                                      style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                              const Text('Cambiar',
                                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              final updated = transaction.copyWith(
                                amount: amount,
                                description: description,
                                date: date,
                                category: category,
                                incomeSourceId: isIncome ? incomeSourceId : null,
                                paymentMethodId: !isIncome ? paymentMethodId : null,
                              );
                              context.read<FinanceBloc>().add(
                                    UpdateTransaction(
                                      transaction: updated,
                                      year: widget.year,
                                      month: widget.month,
                                    ),
                                  );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Transaccion actualizada')),
                              );
                            }
                          },
                          child: const Text(
                            'Guardar Cambios',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
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
                Text(
                  'Ej: Interes, Comision, Seguro desgravamen',
                  style: TextStyle(color: Theme.of(context).textTheme.labelLarge?.color, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descripcion',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa una descripcion' : null,
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
                    if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Monto mayor a 0';
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Sub-item agregado')),
                        );
                      }
                    },
                    child: const Text(
                      'Guardar Sub-item',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
