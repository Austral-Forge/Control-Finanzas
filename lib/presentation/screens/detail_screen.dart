import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/transaction_item.dart';

class DetailScreen extends StatefulWidget {
  final int year;
  final int month;

  const DetailScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar detalles del mes
    context.read<FinanceBloc>().add(
      LoadMonthDetails(year: widget.year, month: widget.month),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'sueldo':
        return Icons.work_outline_rounded;
      case 'ventas':
        return Icons.sell_outlined;
      case 'pagos_tercero':
        return Icons.handshake_outlined;
      case 'tarjetas':
        return Icons.credit_card_outlined;
      case 'prestamos':
        return Icons.account_balance_outlined;
      case 'compras':
        return Icons.shopping_bag_outlined;
      case 'pagos_basicos':
        return Icons.receipt_long_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'sueldo':
        return 'Sueldo';
      case 'ventas':
        return 'Ventas';
      case 'pagos_tercero':
        return 'Pagos de Terceros';
      case 'tarjetas':
        return 'Tarjetas';
      case 'prestamos':
        return 'Préstamos';
      case 'compras':
        return 'Compras';
      case 'pagos_basicos':
        return 'Pagos Básicos';
      case 'otros':
        return 'Otros';
      default:
        return category.toUpperCase();
    }
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
            // Regresar recargando resúmenes
            context.read<FinanceBloc>().add(LoadFinanceSummaries());
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoaded) {
            if (state.isDetailsLoading || state.selectedMonthTransactions == null) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }

            final transactions = state.selectedMonthTransactions!;
            final incomes = transactions.where((t) => t.type == 'income').toList();
            final costs = transactions.where((t) => t.type == 'cost').toList();

            final totalIncome = incomes.fold<double>(0.0, (sum, t) => sum + t.amount);
            final totalCost = costs.fold<double>(0.0, (sum, t) => sum + t.amount);
            final balance = totalIncome - totalCost;

            return Column(
              children: [
                // Resumen rápido en la cabecera
                _buildHeaderSummary(totalIncome, totalCost, balance),
                const SizedBox(height: 10),
                // TabBar para alternar entre Ingresos y Costos
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppTheme.textPrimary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_downward, color: AppTheme.income, size: 18),
                            const SizedBox(width: 8),
                            Text('Ingresos (${incomes.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_upward, color: AppTheme.cost, size: 18),
                            const SizedBox(width: 8),
                            Text('Costos (${costs.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Contenido de Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTransactionList(incomes, 'income'),
                      _buildTransactionList(costs, 'cost'),
                    ],
                  ),
                ),
              ],
            );
          } else if (state is FinanceError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        },
      ),
    );
  }

  Widget _buildHeaderSummary(double income, double cost, double balance) {
    final isDeficit = balance < 0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('Total Ingresos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(income),
                    style: const TextStyle(color: AppTheme.income, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
              Container(width: 1, height: 35, color: Colors.white12),
              Column(
                children: [
                  const Text('Total Costos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(cost),
                    style: const TextStyle(color: AppTheme.cost, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
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
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
              ),
              Text(
                CurrencyFormatter.format(balance),
                style: TextStyle(
                  color: isDeficit ? AppTheme.cost : AppTheme.income,
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

  Widget _buildTransactionList(List<TransactionItem> list, String type) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'income' ? Icons.add_chart : Icons.pie_chart_outline,
              size: 48,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              type == 'income' ? 'No hay registros de ingresos' : 'No hay registros de costos',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildTransactionCard(item);
      },
    );
  }

  Widget _buildTransactionCard(TransactionItem item) {
    final isIncome = item.type == 'income';
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
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar', style: TextStyle(color: AppTheme.cost, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (item.id != null) {
          context.read<FinanceBloc>().add(
            DeleteTransaction(
              id: item.id!,
              year: widget.year,
              month: widget.month,
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro eliminado correctamente'),
              backgroundColor: AppTheme.surfaceLight,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            // Círculo del icono
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(item.category),
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Detalles del texto
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
                        _getCategoryDisplayName(item.category),
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white30, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        '${item.date.day}/${item.date.month}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Monto de dinero
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(item.amount)}',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
