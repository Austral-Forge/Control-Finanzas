import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_event.dart';
import '../blocs/settings_state.dart';
import '../blocs/theme_cubit.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/constants/expense_sections.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/installment.dart';

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
        title: const Text('Configuracion'),
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
          _buildSectionHeader('Apariencia', Icons.palette_outlined, AppTheme.primary),
          const SizedBox(height: 12),
          _buildThemeToggle(),
          const SizedBox(height: 32),
          _buildSectionHeader('Fuentes de Ingreso', Icons.trending_up, AppTheme.income),
          const SizedBox(height: 12),
          _buildSimpleList(
            items: state.incomeSources,
            controller: _incomeController,
            hintText: 'Ej: Sueldo, Freelance, Arriendos...',
            onAdd: () {
              final name = _incomeController.text.trim();
              if (name.isEmpty) return;
              context.read<SettingsBloc>().add(AddIncomeSourceEvent(name: name));
              _incomeController.clear();
            },
            onDelete: (item) => context.read<SettingsBloc>().add(
                  DeleteIncomeSourceEvent(id: (item as IncomeSource).id!),
                ),
            nameGetter: (item) => (item as IncomeSource).name,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Medios de Pago / Tarjetas', Icons.credit_card, AppTheme.primary),
          const SizedBox(height: 12),
          _buildSimpleList(
            items: state.paymentMethods,
            controller: _paymentController,
            hintText: 'Ej: Visa Falabella, Banco de Chile...',
            onAdd: () {
              final name = _paymentController.text.trim();
              if (name.isEmpty) return;
              context.read<SettingsBloc>().add(AddPaymentMethodEvent(name: name));
              _paymentController.clear();
            },
            onDelete: (item) => context.read<SettingsBloc>().add(
                  DeletePaymentMethodEvent(id: (item as PaymentMethod).id!),
                ),
            nameGetter: (item) => (item as PaymentMethod).name,
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Categorias de Gasto', Icons.category_outlined, AppTheme.cost),
          const SizedBox(height: 8),
          Text(
            'Agrega, edita o elimina categorias. Se agrupan por seccion.',
            style: TextStyle(color: context.mutedTextColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildEditableCategories(state.expenseCategories),
          const SizedBox(height: 32),
          _buildSectionHeader('Cuotas / Pagos Pactados', Icons.receipt_long_outlined, AppTheme.savings),
          const SizedBox(height: 8),
          Text(
            'Registra tus compromisos en cuotas para proyectar egresos futuros.',
            style: TextStyle(color: context.mutedTextColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _buildInstallmentsList(state.installments),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Control Finanzas Card v1.0.0',
              style: TextStyle(color: context.mutedTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --- Theme toggle ---

  Widget _buildThemeToggle() {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                color: AppTheme.primary),
            const SizedBox(width: 12),
            Text(isDark ? 'Tema Oscuro' : 'Tema Claro',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ]),
          Switch(
            value: isDark,
            onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  // --- Shared helpers ---

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Text(title, style: context.textTheme.titleLarge),
    ]);
  }

  Widget _buildSimpleList({
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
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(children: [
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.circle, size: 6, color: context.mutedTextColor),
                const SizedBox(width: 12),
                Expanded(child: Text(nameGetter(item), style: const TextStyle(fontSize: 15))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.cost),
                  onPressed: () => onDelete(item),
                  visualDensity: VisualDensity.compact,
                ),
              ]),
            )),
        Divider(color: context.dividerColor),
        Row(children: [
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
          IconButton(icon: const Icon(Icons.add_circle, color: AppTheme.primary), onPressed: onAdd),
        ]),
      ]),
    );
  }

  // --- Editable expense categories ---

  Widget _buildEditableCategories(List<ExpenseCategory> categories) {
    final grouped = <ExpenseSection, List<ExpenseCategory>>{};
    for (final cat in categories) {
      final section = ExpenseSections.parseSection(cat.section);
      grouped.putIfAbsent(section, () => []).add(cat);
    }

    return Column(children: [
      ...ExpenseSection.values.map((section) {
        final cats = grouped[section] ?? [];
        final color = ExpenseSections.colorOf(section);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.cardBorderColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ExpenseSections.getSectionDisplayName(section),
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            if (cats.isEmpty)
              Text('Sin categorias', style: TextStyle(color: context.mutedTextColor, fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) => _buildCategoryChip(cat, color)).toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAddCategoryDialog(section),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: color),
              ),
            ),
          ]),
        );
      }),
    ]);
  }

  Widget _buildCategoryChip(ExpenseCategory cat, Color color) {
    return GestureDetector(
      onTap: () => _showEditCategoryDialog(cat),
      onLongPress: () => _confirmDeleteCategory(cat),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(cat.displayName, style: TextStyle(color: color, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(Icons.edit_outlined, size: 12, color: color.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  void _showAddCategoryDialog(ExpenseSection section) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Ej: Mascotas, Transporte...',
            helperText: ExpenseSections.getSectionDisplayName(section),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              context.read<SettingsBloc>().add(AddExpenseCategoryEvent(
                    displayName: name,
                    section: section.name,
                  ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Categoria "$name" agregada')));
            },
            child: const Text('Agregar', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(ExpenseCategory cat) {
    final controller = TextEditingController(text: cat.displayName);
    var selectedSection = ExpenseSections.parseSection(cat.section);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Categoria'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseSection>(
              initialValue: selectedSection,
              decoration: const InputDecoration(labelText: 'Seccion'),
              items: ExpenseSection.values
                  .map((s) => DropdownMenuItem(
                      value: s, child: Text(ExpenseSections.getSectionDisplayName(s))))
                  .toList(),
              onChanged: (v) => setDialogState(() => selectedSection = v!),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: context.secondaryTextColor)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                context.read<SettingsBloc>().add(UpdateExpenseCategoryEvent(
                      category: ExpenseCategory(
                        id: cat.id,
                        key: cat.key,
                        displayName: name,
                        section: selectedSection.name,
                      ),
                    ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Categoria actualizada')));
              },
              child: const Text('Guardar', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(ExpenseCategory cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoria'),
        content: Text('Eliminar "${cat.displayName}"? Las transacciones existentes conservaran su categoria.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(DeleteExpenseCategoryEvent(id: cat.id!));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Categoria eliminada')));
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.cost, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Installments ---

  Widget _buildInstallmentsList(List<Installment> installments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(children: [
        if (installments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Sin cuotas registradas',
                style: TextStyle(color: context.mutedTextColor, fontSize: 13)),
          )
        else
          ...installments.map((inst) => _buildInstallmentTile(inst)),
        Divider(color: context.dividerColor),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showInstallmentDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Agregar Cuota'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.savings),
          ),
        ),
      ]),
    );
  }

  Widget _buildInstallmentTile(Installment inst) {
    final progress = inst.paidCount / inst.installmentCount;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showInstallmentDialog(existing: inst),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(inst.description,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.cost),
              onPressed: () => _confirmDeleteInstallment(inst),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${CurrencyFormatter.format(inst.monthlyAmount)} x ${inst.installmentCount} cuotas',
                style: TextStyle(color: context.secondaryTextColor, fontSize: 12)),
            Text('${inst.paidCount}/${inst.installmentCount} pagadas',
                style: TextStyle(color: context.mutedTextColor, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: context.cardBorderColor,
              valueColor: AlwaysStoppedAnimation(
                  inst.isCompleted ? AppTheme.income : AppTheme.savings),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text('Saldo pendiente: ${CurrencyFormatter.format(inst.remainingBalance)}',
              style: TextStyle(
                  color: inst.isCompleted ? AppTheme.income : AppTheme.cost,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  void _showInstallmentDialog({Installment? existing}) {
    final isEditing = existing != null;
    final descController = TextEditingController(text: existing?.description ?? '');
    final amountController = TextEditingController(
        text: existing != null
            ? existing.monthlyAmount.toStringAsFixed(existing.monthlyAmount % 1 == 0 ? 0 : 2)
            : '');
    final countController =
        TextEditingController(text: existing?.installmentCount.toString() ?? '');
    final paidController =
        TextEditingController(text: existing?.paidCount.toString() ?? '0');

    final now = DateTime.now();
    int startYear = existing?.startYear ?? now.year;
    int startMonth = existing?.startMonth ?? now.month;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(isEditing ? 'Editar Cuota' : 'Nueva Cuota',
                          style: context.textTheme.headlineMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa una descripcion' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto por cuota (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresa el monto';
                        final parsed = double.tryParse(v);
                        if (parsed == null || parsed <= 0) return 'Monto mayor a 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: countController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total cuotas'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed <= 0) return 'Mayor a 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: paidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Cuotas pagadas'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed < 0) return 'Min 0';
                            return null;
                          },
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetCtx,
                          initialDate: DateTime(startYear, startMonth),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            startYear = picked.year;
                            startMonth = picked.month;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.inputBorderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 20, color: context.secondaryTextColor),
                              const SizedBox(width: 12),
                              Text(
                                  'Inicio: ${CurrencyFormatter.getMonthName(startMonth)} $startYear',
                                  style: const TextStyle(fontSize: 15)),
                            ]),
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
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final inst = Installment(
                            id: existing?.id,
                            description: descController.text.trim(),
                            category: existing?.category ?? 'otros',
                            paymentMethodId: existing?.paymentMethodId,
                            monthlyAmount: double.parse(amountController.text),
                            installmentCount: int.parse(countController.text),
                            paidCount: int.parse(paidController.text),
                            startYear: startYear,
                            startMonth: startMonth,
                          );
                          if (isEditing) {
                            context.read<SettingsBloc>().add(
                                UpdateInstallmentEvent(installment: inst));
                          } else {
                            context
                                .read<SettingsBloc>()
                                .add(AddInstallmentEvent(installment: inst));
                          }
                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEditing
                                ? 'Cuota actualizada'
                                : 'Cuota registrada'),
                          ));
                        },
                        child: Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Cuota',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDeleteInstallment(Installment inst) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cuota'),
        content: Text('Eliminar "${inst.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(DeleteInstallmentEvent(id: inst.id!));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Cuota eliminada')));
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppTheme.cost, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
