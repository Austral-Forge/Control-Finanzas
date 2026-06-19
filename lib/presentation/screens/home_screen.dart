import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/expense_sections.dart';
import '../../data/models/monthly_summary.dart';
import '../../data/models/transaction_item.dart';
import '../widgets/index.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(LoadFinanceSummaries());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wallet, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Control Finanzas'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).textTheme.bodyMedium?.color),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).textTheme.bodyMedium?.color),
            onPressed: () {
              context.read<FinanceBloc>().add(LoadFinanceSummaries());
            },
          ),
        ],
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          } else if (state is FinanceLoaded) {
            if (state.summaries.isEmpty) {
              return const EmptyState();
            }
            return _buildContent(state.summaries, isDark);
          } else if (state is FinanceError) {
            return ErrorState(
              message: state.message,
              onRetry: () {
                context.read<FinanceBloc>().add(LoadFinanceSummaries());
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nueva Transaccion'),
      ),
    );
  }

  Widget _buildContent(List<MonthlySummary> summaries, bool isDark) {
    final totalAhorro = summaries.fold<double>(
      0.0,
      (sum, item) => sum + item.balance,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: BalanceCard(totalBalance: totalAhorro),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Historial Mensual',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (summaries.length > 1)
                Text(
                  '${_currentPage + 1} / ${summaries.length}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.labelLarge?.color,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (summaries.length > 1) _buildPageIndicator(summaries.length, isDark),
        if (summaries.length > 1) const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: summaries.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                child: MonthCard(
                  summary: summary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(
                          year: summary.year,
                          month: summary.month,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary
                : (isDark ? Colors.white24 : Colors.black26),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    String type = 'income';
    String category = '';
    int? incomeSourceId;
    int? paymentMethodId;
    double amount = 0.0;
    String description = '';
    DateTime date = DateTime.now();

    final formKey = GlobalKey<FormState>();

    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is! SettingsLoaded) return;

    final incomeSources = settingsState.incomeSources;
    final paymentMethods = settingsState.paymentMethods;
    final expenseCategories = settingsState.expenseCategories;

    if (incomeSources.isNotEmpty) {
      incomeSourceId = incomeSources.first.id;
      category = incomeSources.first.name;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                          Text(
                            'Anadir Transaccion',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Ingreso')),
                              selected: type == 'income',
                              selectedColor: AppTheme.income.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    type = 'income';
                                    if (incomeSources.isNotEmpty) {
                                      incomeSourceId = incomeSources.first.id;
                                      category = incomeSources.first.name;
                                    }
                                    paymentMethodId = null;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Egreso')),
                              selected: type == 'cost',
                              selectedColor: AppTheme.cost.withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() {
                                    type = 'cost';
                                    if (expenseCategories.isNotEmpty) {
                                      category = expenseCategories.first.key;
                                    }
                                    incomeSourceId = null;
                                    if (paymentMethods.isNotEmpty) {
                                      paymentMethodId = paymentMethods.first.id;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
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
                        decoration: const InputDecoration(
                          labelText: 'Descripcion / Concepto',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa una descripcion';
                          }
                          return null;
                        },
                        onSaved: (value) => description = value!.trim(),
                      ),
                      const SizedBox(height: 16),
                      if (type == 'income' && incomeSources.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: incomeSourceId,
                          decoration: const InputDecoration(
                            labelText: 'Fuente de Ingreso',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          items: incomeSources.map((src) {
                            return DropdownMenuItem<int>(
                              value: src.id,
                              child: Text(src.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              incomeSourceId = value;
                              category = incomeSources
                                  .firstWhere((s) => s.id == value)
                                  .name;
                            });
                          },
                        ),
                      if (type == 'cost' && expenseCategories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: category.isEmpty ? expenseCategories.first.key : category,
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
                          onChanged: (value) {
                            setModalState(() => category = value!);
                          },
                        ),
                      if (type == 'cost' && paymentMethods.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          initialValue: paymentMethodId,
                          decoration: const InputDecoration(
                            labelText: 'Medio de Pago',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Sin especificar'),
                            ),
                            ...paymentMethods.map((pm) {
                              return DropdownMenuItem<int>(
                                value: pm.id,
                                child: Text(pm.name),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setModalState(() => paymentMethodId = value);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setModalState(() => date = pickedDate);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark
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
                                      size: 20, color: Theme.of(context).textTheme.bodyMedium?.color),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Fecha: ${date.day}/${date.month}/${date.year}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              const Text('Cambiar',
                                  style: TextStyle(
                                      color: AppTheme.primary, fontWeight: FontWeight.w600)),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();

                              final newTransaction = TransactionItem(
                                type: type,
                                category: category,
                                amount: amount,
                                description: description,
                                date: date,
                                incomeSourceId: type == 'income' ? incomeSourceId : null,
                                paymentMethodId: type == 'cost' ? paymentMethodId : null,
                              );

                              this.context.read<FinanceBloc>().add(
                                    AddTransaction(transaction: newTransaction),
                                  );

                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(type == 'income'
                                      ? 'Ingreso registrado'
                                      : 'Egreso registrado'),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Guardar Transaccion',
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
              ),
            );
          },
        );
      },
    );
  }
}
