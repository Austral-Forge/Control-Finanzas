import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/financial_analysis.dart';

class AnalysisSection extends StatelessWidget {
  final FinancialAnalysis analysis;

  const AnalysisSection({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Analisis Financiero',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _FinancialScoreCard(analysis: analysis)),
            const SizedBox(width: 12),
            Expanded(child: _AnnualProjectionCard(analysis: analysis)),
          ],
        ),
        if (analysis.hasPreviousData) ...[
          const SizedBox(height: 12),
          _MonthComparisonCard(analysis: analysis),
          if (analysis.overspendingAlerts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OverspendingAlertsCard(alerts: analysis.overspendingAlerts),
          ],
          const SizedBox(height: 12),
          _CategoryTrendsCard(trends: analysis.categoryTrends),
        ],
        const SizedBox(height: 12),
        _BudgetRuleCard(rule: analysis.budgetRule),
        const SizedBox(height: 12),
        _RecommendationsCard(recommendations: analysis.recommendations),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Financial Score
// ---------------------------------------------------------------------------
class _FinancialScoreCard extends StatelessWidget {
  final FinancialAnalysis analysis;
  const _FinancialScoreCard({required this.analysis});

  Color _scoreColor(int score) {
    if (score >= 80) return AppTheme.income;
    if (score >= 60) return AppTheme.savings;
    if (score >= 40) return AppTheme.primary;
    return AppTheme.cost;
  }

  @override
  Widget build(BuildContext context) {
    final score = analysis.financialScore;
    final color = _scoreColor(score);

    return _AnalysisCard(
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 6,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                Text('$score',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Score Financiero',
              style: TextStyle(
                  fontSize: 12, color: context.secondaryTextColor)),
          const SizedBox(height: 2),
          Text(analysis.scoreLabel,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Annual Projection
// ---------------------------------------------------------------------------
class _AnnualProjectionCard extends StatelessWidget {
  final FinancialAnalysis analysis;
  const _AnnualProjectionCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final projection = analysis.annualSavingsProjection;
    final isPositive = projection >= 0;

    return _AnalysisCard(
      child: Column(
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 36,
            color: isPositive ? AppTheme.income : AppTheme.cost,
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(projection.abs()),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppTheme.income : AppTheme.cost,
            ),
          ),
          const SizedBox(height: 4),
          Text('Proyeccion Anual',
              style: TextStyle(
                  fontSize: 12, color: context.secondaryTextColor)),
          Text(
            isPositive ? 'Ahorro estimado' : 'Deficit estimado',
            style: TextStyle(
              fontSize: 11,
              color: isPositive ? AppTheme.income : AppTheme.cost,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month-over-Month Comparison
// ---------------------------------------------------------------------------
class _MonthComparisonCard extends StatelessWidget {
  final FinancialAnalysis analysis;
  const _MonthComparisonCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparacion Mes a Mes',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          _ComparisonRow(
            label: 'Ingresos',
            current: analysis.currentIncome,
            changePercent: analysis.incomeChangePercent,
            isIncrease: analysis.incomeChange >= 0,
            positiveIsGood: true,
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: 'Gastos',
            current: analysis.currentCost,
            changePercent: analysis.costChangePercent,
            isIncrease: analysis.costChange >= 0,
            positiveIsGood: false,
          ),
          const SizedBox(height: 8),
          _ComparisonRow(
            label: 'Balance',
            current: analysis.currentBalance,
            changePercent: analysis.previousBalance != 0
                ? ((analysis.currentBalance - analysis.previousBalance) /
                        analysis.previousBalance.abs()) *
                    100
                : 0,
            isIncrease: analysis.currentBalance >= analysis.previousBalance,
            positiveIsGood: true,
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double current;
  final double changePercent;
  final bool isIncrease;
  final bool positiveIsGood;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.changePercent,
    required this.isIncrease,
    required this.positiveIsGood,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = positiveIsGood ? isIncrease : !isIncrease;
    final color = isGood ? AppTheme.income : AppTheme.cost;
    final arrow = isIncrease ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: context.secondaryTextColor)),
        ),
        Text(CurrencyFormatter.format(current),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(arrow, size: 12, color: color),
              const SizedBox(width: 2),
              Text(
                '${changePercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Category Trends
// ---------------------------------------------------------------------------
class _CategoryTrendsCard extends StatelessWidget {
  final List<CategoryTrend> trends;
  const _CategoryTrendsCard({required this.trends});

  @override
  Widget build(BuildContext context) {
    final display = trends.where((t) => t.currentAmount > 0).take(6).toList();
    if (display.isEmpty) return const SizedBox();

    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendencias por Categoria',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: display.map((t) {
              final hasChange = t.previousAmount > 0;
              final color = !hasChange
                  ? AppTheme.primary
                  : t.isIncrease
                      ? AppTheme.cost
                      : AppTheme.income;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.displayName,
                        style: const TextStyle(fontSize: 11)),
                    if (hasChange) ...[
                      const SizedBox(width: 4),
                      Icon(
                        t.isIncrease
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: color,
                      ),
                      Text(
                        '${t.changePercent.abs().toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overspending Alerts
// ---------------------------------------------------------------------------
class _OverspendingAlertsCard extends StatelessWidget {
  final List<OverspendingAlert> alerts;
  const _OverspendingAlertsCard({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      borderColor: AppTheme.cost.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppTheme.cost),
              const SizedBox(width: 6),
              Text('Alertas de Sobregasto',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppTheme.cost)),
            ],
          ),
          const SizedBox(height: 10),
          for (final alert in alerts.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(alert.displayName,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Text(
                    '+${alert.changePercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.cost),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(alert.currentAmount),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget Rule 50/30/20
// ---------------------------------------------------------------------------
class _BudgetRuleCard extends StatelessWidget {
  final Rule503020 rule;
  const _BudgetRuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Regla 50/30/20',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text('Necesidades / Deseos / Ahorro',
              style: TextStyle(
                  fontSize: 11, color: context.mutedTextColor)),
          const SizedBox(height: 16),
          _RuleBar(
            label: 'Necesidades',
            actual: rule.needsPercent,
            target: Rule503020.needsTarget,
            color: AppTheme.cost,
          ),
          const SizedBox(height: 10),
          _RuleBar(
            label: 'Deseos',
            actual: rule.wantsPercent,
            target: Rule503020.wantsTarget,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _RuleBar(
            label: 'Ahorro',
            actual: rule.savingsPercent,
            target: Rule503020.savingsTarget,
            color: AppTheme.income,
          ),
        ],
      ),
    );
  }
}

class _RuleBar extends StatelessWidget {
  final String label;
  final double actual;
  final double target;
  final Color color;

  const _RuleBar({
    required this.label,
    required this.actual,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clampedActual = actual.clamp(0.0, 100.0);
    final isOver = actual > target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text(
              '${actual.toStringAsFixed(1)}% / ${target.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isOver ? AppTheme.cost : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (clampedActual / 100).clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isOver ? AppTheme.cost : color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              left: (target / 100) *
                  (MediaQuery.of(context).size.width - 80),
              child: Container(
                width: 2,
                height: 8,
                color: context.isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recommendations
// ---------------------------------------------------------------------------
class _RecommendationsCard extends StatelessWidget {
  final List<Recommendation> recommendations;
  const _RecommendationsCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return _AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: AppTheme.primary),
              const SizedBox(width: 6),
              Text('Recomendaciones',
                  style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          for (final rec in recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecommendationTile(recommendation: rec),
            ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final Recommendation recommendation;
  const _RecommendationTile({required this.recommendation});

  Color get _accentColor {
    switch (recommendation.type) {
      case RecommendationType.positive:
        return AppTheme.income;
      case RecommendationType.warning:
        return AppTheme.cost;
      case RecommendationType.neutral:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (recommendation.type) {
      case RecommendationType.positive:
        return Icons.check_circle_outline;
      case RecommendationType.warning:
        return Icons.error_outline;
      case RecommendationType.neutral:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recommendation.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 2),
                Text(recommendation.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card container
// ---------------------------------------------------------------------------
class _AnalysisCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _AnalysisCard({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.cardBorderColor),
      ),
      child: child,
    );
  }
}
