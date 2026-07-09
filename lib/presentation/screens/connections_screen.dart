import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings_bloc.dart';
import '../blocs/settings_event.dart';
import '../blocs/settings_state.dart';
import '../../core/constants/institution_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/bank_connection.dart';
import '../../data/models/payment_method_totals.dart';

/// Pantalla para vincular bancos y casas comerciales. Las tarjetas de cada mes
/// se apilan como un album de discos: deslizando hacia atras o adelante se ve
/// el desglose mensual de ingresos y gastos de las instituciones conectadas.
class ConnectionsScreen extends StatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  static const int _monthsBack = 6;
  static const int _monthsForward = 3;

  PageController? _pageController;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  static String monthKeyOf(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';

  /// Ventana de meses: desde el mes con datos mas antiguo (o [_monthsBack]
  /// atras) hasta [_monthsForward] adelante, siempre incluyendo el actual.
  List<DateTime> _buildMonths(SettingsLoaded state) {
    final now = DateTime.now();
    var earliest = DateTime(now.year, now.month - _monthsBack);
    for (final key in state.monthlyMethodTotals.keys) {
      final year = int.tryParse(key.substring(0, 4));
      final month = int.tryParse(key.substring(5, 7));
      if (year == null || month == null) continue;
      final date = DateTime(year, month);
      if (date.isBefore(earliest)) earliest = date;
    }
    final last = DateTime(now.year, now.month + _monthsForward);
    final months = <DateTime>[];
    var cursor = earliest;
    while (!cursor.isAfter(last)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  void _ensureController(List<DateTime> months) {
    if (_pageController != null) return;
    final now = DateTime.now();
    final currentIndex = months
        .indexWhere((m) => m.year == now.year && m.month == now.month);
    _selectedIndex = currentIndex >= 0 ? currentIndex : months.length - 1;
    _pageController = PageController(
      viewportFraction: 0.42,
      initialPage: _selectedIndex,
    );
  }

  void _goToMonth(int index) {
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conexiones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          final months = _buildMonths(state);
          _ensureController(months);
          final safeIndex = _selectedIndex.clamp(0, months.length - 1);
          final selectedMonth = months[safeIndex];
          final selectedKey = monthKeyOf(selectedMonth);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _InfoBanner(),
                ),
                const SizedBox(height: 24),
                if (state.bankConnections.isNotEmpty) ...[
                  _buildCarouselHeader(months, safeIndex),
                  const SizedBox(height: 12),
                  _buildMonthCarousel(state, months, safeIndex),
                  const SizedBox(height: 24),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _InstitutionsList(
                    state: state,
                    selectedMonthKey: selectedKey,
                    selectedMonthLabel:
                        CurrencyFormatter.getMonthName(selectedMonth.month),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselHeader(List<DateTime> months, int safeIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(
          child: Text('Desglose Mensual', style: context.textTheme.titleLarge),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: safeIndex > 0 ? () => _goToMonth(safeIndex - 1) : null,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: safeIndex < months.length - 1
              ? () => _goToMonth(safeIndex + 1)
              : null,
          visualDensity: VisualDensity.compact,
        ),
      ]),
    );
  }

  Widget _buildMonthCarousel(
      SettingsLoaded state, List<DateTime> months, int safeIndex) {
    final now = DateTime.now();
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _pageController,
        itemCount: months.length,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        itemBuilder: (context, index) {
          final month = months[index];
          final totals = state.connectionsTotalsForMonth(monthKeyOf(month));
          final isFuture =
              DateTime(month.year, month.month).isAfter(DateTime(now.year, now.month));
          return _MonthAlbumCard(
            month: month,
            totals: totals,
            isSelected: index == safeIndex,
            isCurrent: month.year == now.year && month.month == now.month,
            isFuture: isFuture,
            onTap: () => _goToMonth(index),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de mes estilo album
// ---------------------------------------------------------------------------
class _MonthAlbumCard extends StatelessWidget {
  final DateTime month;
  final PaymentMethodTotals totals;
  final bool isSelected;
  final bool isCurrent;
  final bool isFuture;
  final VoidCallback onTap;

  const _MonthAlbumCard({
    required this.month,
    required this.totals,
    required this.isSelected,
    required this.isCurrent,
    required this.isFuture,
    required this.onTap,
  });

  bool get _hasActivity => totals.income > 0 || totals.cost > 0;

  /// Psicologia del color: verde = logro/crecimiento (mes con superavit),
  /// rojo = alerta (deficit), gris neutro = sin actividad (calma, sin juicio).
  Color _accentColor(BuildContext context) {
    if (!_hasActivity) return context.mutedTextColor ?? AppTheme.textMuted;
    return totals.balance >= 0 ? AppTheme.income : AppTheme.cost;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.86,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.55,
          duration: const Duration(milliseconds: 250),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? accent.withValues(alpha: 0.5)
                    : context.cardBorderColor,
                width: isSelected ? 1.5 : 1,
              ),
              gradient: _hasActivity
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.14),
                        context.surfaceColor.withValues(alpha: 0),
                      ],
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.album_rounded, size: 18, color: accent),
                  const Spacer(),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Hoy',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    CurrencyFormatter.getMonthName(month.month),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('${month.year}',
                      style: TextStyle(
                          fontSize: 11, color: context.mutedTextColor)),
                ]),
                if (_hasActivity)
                  Text(
                    '${totals.balance >= 0 ? '+' : '-'}${CurrencyFormatter.format(totals.balance.abs())}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(isFuture ? 'Por venir' : 'Sin movimientos',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: context.mutedTextColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listado de instituciones
// ---------------------------------------------------------------------------
class _InstitutionsList extends StatelessWidget {
  final SettingsLoaded state;
  final String selectedMonthKey;
  final String selectedMonthLabel;

  const _InstitutionsList({
    required this.state,
    required this.selectedMonthKey,
    required this.selectedMonthLabel,
  });

  BankConnection? _connectionFor(Institution institution) {
    for (final connection in state.bankConnections) {
      if (connection.institutionKey == institution.key) return connection;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final type in InstitutionType.values) ...[
          _buildTypeSection(context, type),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildTypeSection(BuildContext context, InstitutionType type) {
    final institutions = InstitutionCatalog.byType(type);
    final isBank = type == InstitutionType.banco;
    // Azul = confianza (bancos); ambar = consumo/precaucion (casas comerciales).
    final typeColor = isBank ? AppTheme.bankTrust : AppTheme.retailWarm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBank
                  ? Icons.account_balance_outlined
                  : Icons.storefront_outlined,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(InstitutionCatalog.typeDisplayName(type),
              style: context.textTheme.titleLarge),
        ]),
        const SizedBox(height: 12),
        ...institutions.map((institution) {
          final connection = _connectionFor(institution);
          return _InstitutionTile(
            institution: institution,
            connection: connection,
            typeColor: typeColor,
            monthLabel: selectedMonthLabel,
            monthTotals: connection != null
                ? state.monthlyTotalsFor(connection, selectedMonthKey)
                : PaymentMethodTotals.empty,
            historicTotals: connection != null
                ? state.totalsFor(connection)
                : PaymentMethodTotals.empty,
          );
        }),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.link_rounded, size: 18, color: AppTheme.primary),
            SizedBox(width: 8),
            Expanded(
              child: Text('Como funcionan las conexiones',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            'Al conectar una institucion se crea un medio de pago con su nombre. '
            'Los ingresos y gastos que registres con ese medio se acumulan aqui, '
            'mes a mes, para que midas cuanto te cuesta y cuanto te aporta cada '
            'banco o casa comercial.',
            style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.sync_rounded, size: 14, color: AppTheme.savings),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Sincronizacion automatica de movimientos (open banking): proximamente.',
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: context.mutedTextColor),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _InstitutionTile extends StatelessWidget {
  final Institution institution;
  final BankConnection? connection;
  final Color typeColor;
  final String monthLabel;
  final PaymentMethodTotals monthTotals;
  final PaymentMethodTotals historicTotals;

  const _InstitutionTile({
    required this.institution,
    required this.connection,
    required this.typeColor,
    required this.monthLabel,
    required this.monthTotals,
    required this.historicTotals,
  });

  bool get isConnected => connection != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? typeColor.withValues(alpha: 0.35)
              : context.cardBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(
              isConnected ? Icons.link_rounded : Icons.link_off_rounded,
              size: 18,
              color: isConnected ? typeColor : context.mutedTextColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(institution.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            if (isConnected)
              TextButton(
                onPressed: () => _confirmDisconnect(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.cost,
                  visualDensity: VisualDensity.compact,
                ),
                child:
                    const Text('Desvincular', style: TextStyle(fontSize: 12)),
              )
            else
              TextButton.icon(
                onPressed: () => _connect(context),
                icon: const Icon(Icons.add_link_rounded, size: 16),
                label: const Text('Conectar', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: typeColor,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ]),
          if (isConnected) ...[
            const SizedBox(height: 8),
            Row(children: [
              _TotalChip(
                label: monthLabel,
                sublabel: 'Ingresos',
                amount: monthTotals.income,
                color: AppTheme.income,
              ),
              const SizedBox(width: 8),
              _TotalChip(
                label: monthLabel,
                sublabel: 'Gastos',
                amount: monthTotals.cost,
                color: AppTheme.cost,
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'Historico: +${CurrencyFormatter.format(historicTotals.income)} · '
              '-${CurrencyFormatter.format(historicTotals.cost)}',
              style: TextStyle(fontSize: 11, color: context.mutedTextColor),
            ),
            if (historicTotals.income == 0 && historicTotals.cost == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Registra movimientos con el medio de pago "${institution.name}" para medir su actividad.',
                  style:
                      TextStyle(fontSize: 11, color: context.mutedTextColor),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _connect(BuildContext context) {
    context
        .read<SettingsBloc>()
        .add(ConnectInstitutionEvent(institution: institution));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '${institution.name} conectado. Se creo el medio de pago "${institution.name}".'),
    ));
  }

  void _confirmDisconnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular Institucion'),
        content: Text(
            'Desvincular "${institution.name}"? El medio de pago y sus movimientos se conservan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: context.secondaryTextColor)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<SettingsBloc>()
                  .add(DisconnectInstitutionEvent(id: connection!.id!));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${institution.name} desvinculado')));
            },
            child: const Text('Desvincular',
                style: TextStyle(
                    color: AppTheme.cost, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final double amount;
  final Color color;

  const _TotalChip({
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$sublabel · $label',
              style:
                  TextStyle(fontSize: 10, color: context.secondaryTextColor)),
          const SizedBox(height: 2),
          Text(CurrencyFormatter.format(amount),
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}
