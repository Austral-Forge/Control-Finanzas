import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/expense_sections.dart';
import '../../core/constants/transaction_types.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../data/models/transaction_item.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_state.dart';

/// Hoja modal reutilizable para crear o editar una transacción.
///
/// - Si [initial] es `null`, opera en modo "crear" (permite elegir el tipo).
/// - Si [initial] no es `null`, opera en modo "editar" (el tipo queda fijo).
///
/// Devuelve la transacción resultante a través de [onSubmit]; el llamador
/// decide qué evento despachar y qué mensaje de confirmación mostrar.
class TransactionFormSheet extends StatefulWidget {
  final TransactionItem? initial;
  final void Function(TransactionItem transaction) onSubmit;

  const TransactionFormSheet({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  bool get isEditing => initial != null;

  /// Presenta el formulario como bottom sheet. Requiere que [SettingsBloc] esté
  /// en estado [SettingsLoaded]; de lo contrario no hace nada.
  static Future<void> show(
    BuildContext context, {
    TransactionItem? initial,
    required void Function(TransactionItem transaction) onSubmit,
  }) {
    if (context.read<SettingsBloc>().state is! SettingsLoaded) {
      return Future.value();
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsBloc>(),
        child: TransactionFormSheet(initial: initial, onSubmit: onSubmit),
      ),
    );
  }

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _type;
  String _category = '';
  int? _incomeSourceId;
  int? _paymentMethodId;
  DateTime _date = DateTime.now();

  bool get _isIncome => TransactionType.isIncome(_type);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final settings = context.read<SettingsBloc>().state as SettingsLoaded;

    if (initial != null) {
      _type = initial.type;
      _category = initial.category;
      _incomeSourceId = initial.incomeSourceId;
      _paymentMethodId = initial.paymentMethodId;
      _date = initial.date;
      _amountController.text =
          initial.amount.toStringAsFixed(initial.amount % 1 == 0 ? 0 : 2);
      _descriptionController.text = initial.description;
    } else {
      _type = TransactionType.income;
      if (settings.incomeSources.isNotEmpty) {
        _incomeSourceId = settings.incomeSources.first.id;
        _category = settings.incomeSources.first.name;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectType(String type, SettingsLoaded settings) {
    setState(() {
      _type = type;
      if (_isIncome) {
        _paymentMethodId = null;
        if (settings.incomeSources.isNotEmpty) {
          _incomeSourceId = settings.incomeSources.first.id;
          _category = settings.incomeSources.first.name;
        }
      } else {
        _incomeSourceId = null;
        if (settings.expenseCategories.isNotEmpty) {
          _category = settings.expenseCategories.first.key;
        }
        if (settings.paymentMethods.isNotEmpty) {
          _paymentMethodId = settings.paymentMethods.first.id;
        }
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text.trim();
    final incomeSourceId = _isIncome ? _incomeSourceId : null;
    final paymentMethodId = _isIncome ? null : _paymentMethodId;

    final initial = widget.initial;
    final result = initial != null
        ? initial.copyWith(
            amount: amount,
            description: description,
            date: _date,
            category: _category,
            incomeSourceId: incomeSourceId,
            paymentMethodId: paymentMethodId,
          )
        : TransactionItem(
            type: _type,
            category: _category,
            amount: amount,
            description: description,
            date: _date,
            incomeSourceId: incomeSourceId,
            paymentMethodId: paymentMethodId,
          );

    Navigator.pop(context);
    widget.onSubmit(result);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    if (settings is! SettingsLoaded) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (widget.isEditing)
                _buildTypeBadge()
              else
                _buildTypeSelector(settings),
              const SizedBox(height: 20),
              _buildAmountField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              ..._buildCategoryFields(settings),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.isEditing ? 'Editar Transaccion' : 'Anadir Transaccion',
          style: context.textTheme.headlineMedium,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final color = _isIncome ? AppTheme.income : AppTheme.cost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _isIncome ? 'Ingreso' : 'Egreso',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildTypeSelector(SettingsLoaded settings) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Ingreso')),
            selected: _isIncome,
            selectedColor: AppTheme.income.withValues(alpha: 0.2),
            onSelected: (val) {
              if (val) _selectType(TransactionType.income, settings);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Egreso')),
            selected: !_isIncome,
            selectedColor: AppTheme.cost.withValues(alpha: 0.2),
            onSelected: (val) {
              if (val) _selectType(TransactionType.cost, settings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      style: const TextStyle(fontSize: 18),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Monto (\$)',
        prefixIcon: Icon(Icons.attach_money),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Ingresa un monto';
        final parsed = double.tryParse(value);
        if (parsed == null || parsed <= 0) return 'Ingresa un monto mayor a 0';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
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
    );
  }

  List<Widget> _buildCategoryFields(SettingsLoaded settings) {
    if (_isIncome) {
      if (settings.incomeSources.isEmpty) return const [];
      return [
        DropdownButtonFormField<int>(
          initialValue: _incomeSourceId,
          decoration: const InputDecoration(
            labelText: 'Fuente de Ingreso',
            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
          ),
          items: settings.incomeSources
              .map((src) =>
                  DropdownMenuItem<int>(value: src.id, child: Text(src.name)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _incomeSourceId = value;
              _category =
                  settings.incomeSources.firstWhere((s) => s.id == value).name;
            });
          },
        ),
      ];
    }

    return [
      if (settings.expenseCategories.isNotEmpty)
        DropdownButtonFormField<String>(
          initialValue: _category.isEmpty
              ? settings.expenseCategories.first.key
              : _category,
          decoration: const InputDecoration(
            labelText: 'Categoria de Gasto',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: settings.expenseCategories.map((cat) {
            final sectionLabel = ExpenseSections.getSectionDisplayName(
              ExpenseSections.parseSection(cat.section),
            );
            return DropdownMenuItem<String>(
              value: cat.key,
              child: Text('${cat.displayName} ($sectionLabel)'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
      if (settings.paymentMethods.isNotEmpty) ...[
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _paymentMethodId,
          decoration: const InputDecoration(
            labelText: 'Medio de Pago',
            prefixIcon: Icon(Icons.credit_card_outlined),
          ),
          items: [
            const DropdownMenuItem<int>(
                value: null, child: Text('Sin especificar')),
            ...settings.paymentMethods.map((pm) =>
                DropdownMenuItem<int>(value: pm.id, child: Text(pm.name))),
          ],
          onChanged: (value) => setState(() => _paymentMethodId = value),
        ),
      ],
    ];
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => _date = picked);
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
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 20, color: context.secondaryTextColor),
                const SizedBox(width: 12),
                Text('Fecha: ${_date.day}/${_date.month}/${_date.year}',
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
            const Text('Cambiar',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _submit,
        child: Text(
          widget.isEditing ? 'Guardar Cambios' : 'Guardar Transaccion',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
