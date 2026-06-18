import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_event.dart';
import '../blocs/settings_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/expense_sections.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _incomeController = TextEditingController();
  final _paymentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          } else if (state is SettingsLoaded) {
            return _buildContent(state);
          } else if (state is SettingsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(SettingsLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Fuentes de Ingreso', Icons.trending_up, AppTheme.income),
          const SizedBox(height: 12),
          _buildEditableList(
            items: state.incomeSources,
            controller: _incomeController,
            hintText: 'Ej: Sueldo, Freelance, Arriendos...',
            onAdd: () {
              final name = _incomeController.text.trim();
              if (name.isEmpty) return;
              context.read<SettingsBloc>().add(AddIncomeSourceEvent(name: name));
              _incomeController.clear();
            },
            onDelete: (item) {
              context.read<SettingsBloc>().add(
                    DeleteIncomeSourceEvent(id: (item as IncomeSource).id!),
                  );
            },
            nameGetter: (item) => (item as IncomeSource).name,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Medios de Pago / Tarjetas', Icons.credit_card, AppTheme.primary),
          const SizedBox(height: 12),
          _buildEditableList(
            items: state.paymentMethods,
            controller: _paymentController,
            hintText: 'Ej: Visa Falabella, Banco de Chile...',
            onAdd: () {
              final name = _paymentController.text.trim();
              if (name.isEmpty) return;
              context.read<SettingsBloc>().add(AddPaymentMethodEvent(name: name));
              _paymentController.clear();
            },
            onDelete: (item) {
              context.read<SettingsBloc>().add(
                    DeletePaymentMethodEvent(id: (item as PaymentMethod).id!),
                  );
            },
            nameGetter: (item) => (item as PaymentMethod).name,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader(
              'Categorías de Gasto', Icons.category_outlined, AppTheme.cost),
          const SizedBox(height: 8),
          const Text(
            'Las categorías están predefinidas y se clasifican automáticamente en secciones.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildExpenseCategoriesReadOnly(state.expenseCategories),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildEditableList({
    required List<dynamic> items,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onAdd,
    required Function(dynamic) onDelete,
    required String Function(dynamic) nameGetter,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 6, color: AppTheme.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      nameGetter(item),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.cost),
                    onPressed: () => onDelete(item),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          }),
          const Divider(color: Colors.white12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCategoriesReadOnly(List<ExpenseCategory> categories) {
    final grouped = <ExpenseSection, List<ExpenseCategory>>{};
    for (final cat in categories) {
      final section = ExpenseSections.getSection(cat.key);
      grouped.putIfAbsent(section, () => []).add(cat);
    }

    return Column(
      children: ExpenseSection.values.map((section) {
        final cats = grouped[section] ?? [];
        if (cats.isEmpty) return const SizedBox();

        final sectionColor = switch (section) {
          ExpenseSection.indispensable => AppTheme.cost,
          ExpenseSection.recurrente => AppTheme.primary,
          ExpenseSection.extraordinario => AppTheme.savings,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ExpenseSections.getSectionDisplayName(section),
                style: TextStyle(
                  color: sectionColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sectionColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cat.displayName,
                      style: TextStyle(color: sectionColor, fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
