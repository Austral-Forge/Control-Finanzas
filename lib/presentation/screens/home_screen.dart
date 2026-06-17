import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/monthly_summary.dart';
import '../../data/models/transaction_item.dart';
import '../widgets/index.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar los resúmenes financieros al iniciar
    context.read<FinanceBloc>().add(LoadFinanceSummaries());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wallet, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Mis Finanzas 2026'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
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
            return _buildContent(state.summaries);
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
        label: const Text('Nueva Transacción'),
      ),
    );
  }


  Widget _buildContent(List<MonthlySummary> summaries) {
    // Calcular balance general total de ahorro
    final totalAhorro = summaries.fold<double>(
      0.0,
      (sum, item) => sum + item.balance,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de balance general (Ahorro Total acumulado)
          BalanceCard(totalBalance: totalAhorro),
          const SizedBox(height: 30),
          Text(
            'Historial Mensual',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          // Lista de meses
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summaries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final summary = summaries[index];
              return MonthCard(
                summary: summary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        year: summary.year,
                        month: summary.month,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }


  void _showAddTransactionDialog(BuildContext context) {
    String type = 'income';
    String category = 'sueldo';
    double amount = 0.0;
    String description = '';
    DateTime date = DateTime.now();

    final formKey = GlobalKey<FormState>();

    // Categorías disponibles
    final incomeCategories = ['sueldo', 'ventas', 'pagos_tercero', 'otros'];
    final costCategories = ['tarjetas', 'prestamos', 'compras', 'pagos_basicos', 'otros'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeCategories = type == 'income' ? incomeCategories : costCategories;
            // Validar que la categoría seleccionada esté en la lista activa
            if (!activeCategories.contains(category)) {
              category = activeCategories.first;
            }

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
                        Text(
                          'Añadir Transacción',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selector de tipo (Ingreso / Costo)
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Ingreso')),
                            selected: type == 'income',
                            selectedColor: AppTheme.income.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  type = 'income';
                                  category = 'sueldo';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Costo')),
                            selected: type == 'cost',
                            selectedColor: AppTheme.cost.withOpacity(0.2),
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  type = 'cost';
                                  category = 'tarjetas';
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Campo de Monto
                    TextFormField(
                      style: const TextStyle(fontSize: 18),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monto (\$)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa un monto';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Ingresa un monto mayor a 0';
                        }
                        return null;
                      },
                      onSaved: (value) => amount = double.parse(value!),
                    ),
                    const SizedBox(height: 16),
                    // Campo de Descripción
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Descripción / Concepto',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa una descripción';
                        }
                        return null;
                      },
                      onSaved: (value) => description = value!.trim(),
                    ),
                    const SizedBox(height: 16),
                    // Selector de Categoría
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: activeCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          category = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Selector de Fecha
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (pickedDate != null) {
                          setModalState(() {
                            date = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.textSecondary),
                                const SizedBox(width: 12),
                                Text(
                                  'Fecha: ${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            const Text('Cambiar', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón de Guardar
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
                            );
                            
                            context.read<FinanceBloc>().add(
                              AddTransaction(transaction: newTransaction),
                            );

                            Navigator.pop(context);
                          }
                        },
                        child: const Text(
                          'Guardar Transacción',
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
      },
    );
  }
}
