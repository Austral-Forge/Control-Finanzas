import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openSavingsConfirmation(state);
    });
  }

  /// Validación para empezar el mes: el usuario confirma cuánto ahorro real
  /// arrastra antes de partir el mes siguiente.
  void _openSavingsConfirmation(FinanceLoaded state) {
    final totalSavings =
        state.summaries.fold<double>(0.0, (sum, s) => sum + s.balance);
    final now = DateTime.now();
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: BalanceCard(totalBalance: totalSavings),
          ),
          const SizedBox(height: 20),
          _buildCarouselHeader(currentIndex, totalCards),
          const SizedBox(height: 12),
          SizedBox(
            height: 290,
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalCards,
              itemBuilder: (context, index) {
                if (index < projections.length) {
                  return _build3DCard(
                      index, _MonthCarouselCard(projection: projections[index]));
                }
                return _build3DCard(
                  index,
                  _ProjectedCarouselCard(
                    projected: projected,
                    onConfirmPending: () => _openSavingsConfirmation(state),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildPageDots(totalCards, currentIndex),
          const SizedBox(height: 20),
          _buildQuickAddButtons(),
        ],
      ),
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

  Widget _build3DCard(int index, Widget card) {
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
      child: Opacity(opacity: opacity.toDouble(), child: card),
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

  /// Entrada rápida: lo más importante es registrar un movimiento en 2 toques.
  Widget _buildQuickAddButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickAddButton(
              label: 'Ingreso',
              icon: Icons.arrow_downward_rounded,
              color: AppTheme.income,
              onTap: () => _openAddTransaction(TransactionType.income),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickAddButton(
              label: 'Egreso',
              icon: Icons.arrow_upward_rounded,
              color: AppTheme.cost,
              onTap: () => _openAddTransaction(TransactionType.cost),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddTransaction(String type) {
    TransactionFormSheet.show(
      context,
      initialType: type,
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

class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: color),
        label: Text('+ $label',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de un mes: el resumen macro Ingresos − Egresos = Ahorro/Pérdida.
class _MonthCarouselCard extends StatelessWidget {
  final MonthlyProjection projection;

  const _MonthCarouselCard({required this.projection});

  @override
  Widget build(BuildContext context) {
    final summary = projection.summary;
    final balance = summary.balance;
    final isDeficit = balance < 0;
    final monthName = CurrencyFormatter.getMonthName(summary.month);
    final balanceColor = isDeficit ? AppTheme.cost : AppTheme.income;

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
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: balanceColor.withValues(alpha: context.isDark ? 0.12 : 0.07),
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
            const SizedBox(height: 20),
            _CardRow(
                label: 'Ingresos',
                value: summary.totalIncome,
                color: AppTheme.income),
            const SizedBox(height: 10),
            _CardRow(
                label: 'Egresos',
                value: summary.totalCost,
                color: AppTheme.cost),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.dividerColor, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isDeficit ? 'Perdida' : 'Ahorro',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.primaryTextColor)),
                Text(CurrencyFormatter.format(balance.abs()),
                    style: TextStyle(
                        color: balanceColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Ver en que se fue',
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
        isDeficit ? 'Perdida' : 'Ahorro',
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
            style: TextStyle(color: context.secondaryTextColor, fontSize: 14)),
        Text(CurrencyFormatter.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
      ],
    );
  }
}

/// Tarjeta del mes proyectado (último slot del carrusel). Al tocarla con la
/// confirmación pendiente se abre la validación para empezar el mes.
class _ProjectedCarouselCard extends StatelessWidget {
  final ProjectedMonth projected;
  final VoidCallback onConfirmPending;

  const _ProjectedCarouselCard({
    required this.projected,
    required this.onConfirmPending,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = CurrencyFormatter.getMonthName(projected.month);

    return GestureDetector(
      onTap: projected.savingsConfirmed ? null : onConfirmPending,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(22),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            const SizedBox(height: 16),
            _CardRow(
                label: 'Saldo arrastrado',
                value: projected.carriedBalance,
                color: projected.carriedBalance >= 0
                    ? AppTheme.income
                    : AppTheme.cost),
            if (projected.projectedIncomes > 0) ...[
              const SizedBox(height: 6),
              _CardRow(
                  label: '+ Cuotas por cobrar',
                  value: projected.projectedIncomes,
                  color: AppTheme.income),
            ],
            const SizedBox(height: 6),
            _CardRow(
                label: '- Cuotas por pagar',
                value: projected.projectedExpenses,
                color: AppTheme.cost),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: context.dividerColor, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Balance Proyectado',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.primaryTextColor)),
                Text(CurrencyFormatter.format(projected.projectedBalance),
                    style: TextStyle(
                        color: projected.isDeficit
                            ? AppTheme.cost
                            : AppTheme.income,
                        fontWeight: FontWeight.w800,
                        fontSize: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                projected.savingsConfirmed
                    ? (projected.hasInstallments
                        ? '${projected.dueInstallments.length} cuota(s) este mes'
                        : 'Sin cuotas comprometidas')
                    : 'Toca para confirmar y empezar el mes',
                style: TextStyle(
                  color: projected.savingsConfirmed
                      ? context.mutedTextColor
                      : AppTheme.primary,
                  fontWeight: projected.savingsConfirmed
                      ? FontWeight.w400
                      : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
