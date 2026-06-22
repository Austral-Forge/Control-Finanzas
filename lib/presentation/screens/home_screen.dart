import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/finance_bloc.dart';
import '../blocs/finance_event.dart';
import '../blocs/finance_state.dart';
import '../../core/constants/transaction_types.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_state.dart';
import '../../data/models/monthly_projection.dart';
import '../../data/models/projected_month.dart';
import '../widgets/index.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;
  double _page = 0.0;
  bool _initialPageSet = false;
  bool _savingsDialogShown = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82)
      ..addListener(() {
        setState(() => _page = _pageController.page ?? 0.0);
      });
    context.read<FinanceBloc>().add(LoadFinanceSummaries());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          } else if (state is FinanceLoaded) {
            if (state.summaries.isEmpty) return const EmptyState();
            _showSavingsDialogIfNeeded(state);
            return _buildContent(state);
          } else if (state is FinanceError) {
            return ErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<FinanceBloc>().add(LoadFinanceSummaries()),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Nueva Transaccion'),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
          icon: Icon(Icons.settings_outlined, color: context.secondaryTextColor),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: context.secondaryTextColor),
          onPressed: () =>
              context.read<FinanceBloc>().add(LoadFinanceSummaries()),
        ),
      ],
    );
  }

  void _showSavingsDialogIfNeeded(FinanceLoaded state) {
    if (_savingsDialogShown || !state.hasPendingSavingsConfirmation) return;
    _savingsDialogShown = true;
    final totalSavings =
        state.summaries.fold<double>(0.0, (sum, s) => sum + s.balance);
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SavingsConfirmationSheet.show(
        context,
        calculatedSavings: totalSavings,
        year: now.year,
        month: now.month,
        onConfirm: (amount) {
          context.read<FinanceBloc>().add(ConfirmSavings(
                year: now.year,
                month: now.month,
                originalAmount: totalSavings,
                confirmedAmount: amount,
              ));
        },
      );
    });
  }

  Widget _buildContent(FinanceLoaded state) {
    final summaries = state.summaries;
    final chronological = summaries.reversed.toList();
    final projections = MonthlyProjection.fromChronological(
      chronological,
      confirmations: state.savingsConfirmations,
    );
    final totalSavings =
        summaries.fold<double>(0.0, (sum, s) => sum + s.balance);

    final settingsState = context.watch<SettingsBloc>().state;
    final installments = settingsState is SettingsLoaded
        ? settingsState.installments
        : const <dynamic>[];

    final lastSummary = chronological.last;
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month}';
    final savingsConfirmed =
        state.savingsConfirmations.containsKey(currentKey);

    final projected = ProjectedMonth.next(
      lastYear: lastSummary.year,
      lastMonth: lastSummary.month,
      carriedBalance: totalSavings,
      installments: installments.cast(),
      savingsConfirmed: savingsConfirmed,
    );

    final totalCards = projections.length + 1;
    _scheduleInitialPage(totalCards);

    final currentIndex = _page.round().clamp(0, totalCards - 1);
    final isProjectedSelected = currentIndex == projections.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: BalanceCard(totalBalance: totalSavings),
        ),
        const SizedBox(height: 20),
        _buildCarouselHeader(currentIndex, totalCards),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalCards,
            itemBuilder: (context, index) {
              if (index < projections.length) {
                return _build3DCard(index, projections[index]);
              }
              return _build3DProjectedCard(index, projected);
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPageDots(totalCards, currentIndex),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
            child: isProjectedSelected
                ? _ProjectedMonthChart(projected: projected)
                : _MonthChart(projection: projections[currentIndex]),
          ),
        ),
      ],
    );
  }

  /// Posiciona el carrusel en el mes más reciente la primera vez que se monta.
  void _scheduleInitialPage(int count) {
    if (_initialPageSet || count <= 1) return;
    _initialPageSet = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(count - 1);
      }
    });
  }

  Widget _buildCarouselHeader(int currentIndex, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Historial Mensual', style: context.textTheme.headlineMedium),
              Text('${currentIndex + 1} / $total',
                  style: TextStyle(color: context.mutedTextColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.swipe, size: 14, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text('Desliza para ver otros meses',
                  style: TextStyle(color: context.mutedTextColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DCard(int index, MonthlyProjection projection) {
    final distance = index - _page;
    final rotationY = distance * 0.4;
    final scale = 1 - (distance.abs() * 0.15).clamp(0.0, 0.3);
    final opacity = (1 - (distance.abs() * 0.3)).clamp(0.4, 1.0);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateY(rotationY);
    final scaled = transform * Matrix4.diagonal3Values(scale, scale, 1.0);

    return Transform(
      alignment: Alignment.center,
      transform: scaled,
      child: Opacity(
        opacity: opacity.toDouble(),
        child: _MonthCarouselCard(projection: projection),
      ),
    );
  }

  Widget _build3DProjectedCard(int index, ProjectedMonth projected) {
    final distance = index - _page;
    final rotationY = distance * 0.4;
    final scale = 1 - (distance.abs() * 0.15).clamp(0.0, 0.3);
    final opacity = (1 - (distance.abs() * 0.3)).clamp(0.4, 1.0);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.002)
      ..rotateY(rotationY);
    final scaled = transform * Matrix4.diagonal3Values(scale, scale, 1.0);

    return Transform(
      alignment: Alignment.center,
      transform: scaled,
      child: Opacity(
        opacity: opacity.toDouble(),
        child: _ProjectedCarouselCard(projected: projected),
      ),
    );
  }

  Widget _buildPageDots(int count, int current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary
                : (context.isDark ? Colors.white24 : Colors.black26),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  void _openAddTransaction() {
    TransactionFormSheet.show(
      context,
      onSubmit: (transaction) {
        context.read<FinanceBloc>().add(AddTransaction(transaction: transaction));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TransactionType.isIncome(transaction.type)
                ? 'Ingreso registrado'
                : 'Egreso registrado'),
          ),
        );
      },
    );
  }
}

/// Tarjeta de un mes dentro del carrusel 3D.
class _MonthCarouselCard extends StatelessWidget {
  final MonthlyProjection projection;

  const _MonthCarouselCard({required this.projection});

  @override
  Widget build(BuildContext context) {
    final summary = projection.summary;
    final isDeficit = summary.isDeficit;
    final monthName = CurrencyFormatter.getMonthName(summary.month);
    final monthBalance = projection.effectiveIncome - summary.totalCost;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailScreen(year: summary.year, month: summary.month),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: context.isDark ? 0.15 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$monthName ${summary.year}',
                    style: context.textTheme.titleLarge),
                _StatusBadge(isDeficit: isDeficit),
              ],
            ),
            const SizedBox(height: 14),
            _CardRow(label: 'Ingresos', value: summary.totalIncome, color: AppTheme.income),
            if (projection.hasCarriedSavings) ...[
              const SizedBox(height: 4),
              _CardRow(
                  label: '+ Ahorro anterior',
                  value: projection.carriedSavings,
                  color: AppTheme.savings),
            ],
            const SizedBox(height: 4),
            _CardRow(label: 'Egresos', value: summary.totalCost, color: AppTheme.cost),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: context.dividerColor, height: 1),
            ),
            _CardTotalRow(
                label: 'Ingreso Efectivo',
                value: projection.effectiveIncome,
                color: AppTheme.income),
            const SizedBox(height: 4),
            _CardTotalRow(
              label: 'Balance del Mes',
              value: monthBalance,
              color: monthBalance < 0 ? AppTheme.cost : AppTheme.income,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ver detalle',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios,
                    size: 10, color: AppTheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isDeficit;

  const _StatusBadge({required this.isDeficit});

  @override
  Widget build(BuildContext context) {
    final color = isDeficit ? AppTheme.cost : AppTheme.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isDeficit ? 'Deficit' : 'Ahorro',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CardRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: context.secondaryTextColor, fontSize: 13)),
        Text(CurrencyFormatter.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _CardTotalRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _CardTotalRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.primaryTextColor)),
        Text(CurrencyFormatter.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}

/// Gráfico de barras del mes: ingresos, ahorro previo, egresos y ahorro potencial.
class _MonthChart extends StatelessWidget {
  final MonthlyProjection projection;

  const _MonthChart({required this.projection});

  List<String> get _labels => projection.hasCarriedSavings
      ? const ['Ingresos', 'Ahorro\nAnt.', 'Egresos', 'Ahorro\nPot.']
      : const ['Ingresos', 'Egresos', 'Ahorro\nPot.'];

  List<String> get _tooltipLabels => projection.hasCarriedSavings
      ? const ['Ingresos', 'Ahorro Ant.', 'Egresos', 'Ahorro Pot.']
      : const ['Ingresos', 'Egresos', 'Ahorro Pot.'];

  @override
  Widget build(BuildContext context) {
    final summary = projection.summary;
    final potential = projection.savingsPotential;
    final monthName = CurrencyFormatter.getMonthName(summary.month);

    final maxValue = [
      summary.totalIncome,
      summary.totalCost,
      projection.carriedSavings,
      potential.abs(),
    ].reduce(math.max);
    final ceiling = maxValue > 0 ? maxValue * 1.2 : 1000.0;

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
          Text('Resumen $monthName', style: context.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Ganancia vs Perdidas y Ahorro Potencial',
              style: TextStyle(color: context.mutedTextColor, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ceiling,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${_tooltipLabels[groupIndex]}\n${CurrencyFormatter.format(rod.toY)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_labels[idx],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10, color: context.mutedTextColor)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: _buildBarGroups(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ChartLegend(
                label: 'Tasa Ahorro',
                value: '${(projection.savingsRate * 100).toStringAsFixed(1)}%',
                color: potential >= 0 ? AppTheme.income : AppTheme.cost,
              ),
              _ChartLegend(
                label: 'Ahorro Pot.',
                value: CurrencyFormatter.format(potential),
                color: potential >= 0 ? AppTheme.savings : AppTheme.cost,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final summary = projection.summary;
    final potential = projection.savingsPotential;

    final bars = <_Bar>[
      _Bar(summary.totalIncome, AppTheme.income),
      if (projection.hasCarriedSavings)
        _Bar(projection.carriedSavings, AppTheme.savings),
      _Bar(summary.totalCost, AppTheme.cost),
      _Bar(
        potential.abs(),
        potential >= 0 ? AppTheme.primary : AppTheme.cost.withValues(alpha: 0.6),
      ),
    ];

    return [
      for (var i = 0; i < bars.length; i++)
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: bars[i].value,
            color: bars[i].color,
            width: 28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ]),
    ];
  }
}

class _Bar {
  final double value;
  final Color color;
  const _Bar(this.value, this.color);
}

class _ChartLegend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ChartLegend(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(color: context.mutedTextColor, fontSize: 11)),
      ],
    );
  }
}

/// Tarjeta del mes proyectado (último slot del carrusel).
class _ProjectedCarouselCard extends StatelessWidget {
  final ProjectedMonth projected;

  const _ProjectedCarouselCard({required this.projected});

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(projected.month);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: context.isDark ? 0.12 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$monthName ${projected.year}',
                  style: context.textTheme.titleLarge),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: projected.savingsConfirmed
                      ? AppTheme.primary.withValues(alpha: 0.12)
                      : AppTheme.cost.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  projected.savingsConfirmed
                      ? 'Proyectado'
                      : 'Pendiente confirmar',
                  style: TextStyle(
                    color: projected.savingsConfirmed
                        ? AppTheme.primary
                        : AppTheme.cost,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CardRow(
              label: 'Saldo arrastrado',
              value: projected.carriedBalance,
              color: projected.carriedBalance >= 0
                  ? AppTheme.income
                  : AppTheme.cost),
          if (projected.hasInstallments) ...[
            const SizedBox(height: 4),
            ...projected.dueInstallments.map((inst) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _CardRow(
                      label: '- ${inst.description}',
                      value: inst.dueAmountForMonth(
                          projected.year, projected.month),
                      color: AppTheme.cost),
                )),
            const SizedBox(height: 2),
            _CardRow(
                label: 'Total cuotas',
                value: projected.projectedExpenses,
                color: AppTheme.cost),
          ],
          if (!projected.hasInstallments) ...[
            const SizedBox(height: 4),
            _CardRow(
                label: 'Cuotas del mes', value: 0, color: AppTheme.cost),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.dividerColor, height: 1),
          ),
          _CardTotalRow(
            label: 'Balance Proyectado',
            value: projected.projectedBalance,
            color: projected.isDeficit ? AppTheme.cost : AppTheme.income,
          ),
          const Spacer(),
          Center(
            child: Text(
              projected.hasInstallments
                  ? '${projected.dueInstallments.length} cuota(s) pendiente(s)'
                  : 'Sin cuotas comprometidas',
              style: TextStyle(color: context.mutedTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de barras para el mes proyectado.
class _ProjectedMonthChart extends StatelessWidget {
  final ProjectedMonth projected;

  const _ProjectedMonthChart({required this.projected});

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(projected.month);
    final carried = projected.carriedBalance;
    final expenses = projected.projectedExpenses;
    final balance = projected.projectedBalance;

    final maxValue = [carried.abs(), expenses, balance.abs()]
        .reduce(math.max);
    final ceiling = maxValue > 0 ? maxValue * 1.2 : 1000.0;

    final labels = ['Saldo\nAnterior', 'Cuotas\nProyect.', 'Balance\nProyect.'];
    final tooltipLabels = ['Saldo Anterior', 'Cuotas Proyectadas', 'Balance Proyectado'];

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
          Text('Proyeccion $monthName ${projected.year}',
              style: context.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Saldo arrastrado vs Cuotas comprometidas',
              style: TextStyle(color: context.mutedTextColor, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: ceiling,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${tooltipLabels[groupIndex]}\n${CurrencyFormatter.format(rod.toY)}',
                      const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[idx],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.mutedTextColor)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: carried.abs(),
                      color: carried >= 0 ? AppTheme.savings : AppTheme.cost,
                      width: 32,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: expenses,
                      color: AppTheme.cost,
                      width: 32,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(
                      toY: balance.abs(),
                      color: balance >= 0
                          ? AppTheme.primary
                          : AppTheme.cost.withValues(alpha: 0.6),
                      width: 32,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ChartLegend(
                label: 'Saldo Arrastrado',
                value: CurrencyFormatter.format(carried),
                color: carried >= 0 ? AppTheme.savings : AppTheme.cost,
              ),
              _ChartLegend(
                label: 'Balance Proyect.',
                value: CurrencyFormatter.format(balance),
                color: balance >= 0 ? AppTheme.primary : AppTheme.cost,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
