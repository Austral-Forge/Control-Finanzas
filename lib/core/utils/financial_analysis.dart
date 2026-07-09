import '../../data/models/transaction_item.dart';
import 'currency_formatter.dart';

class CategoryTrend {
  final String categoryKey;
  final String displayName;
  final double currentAmount;
  final double previousAmount;

  CategoryTrend({
    required this.categoryKey,
    required this.displayName,
    required this.currentAmount,
    required this.previousAmount,
  });

  double get change => currentAmount - previousAmount;
  double get changePercent =>
      previousAmount > 0 ? (change / previousAmount) * 100 : 0;
  bool get isIncrease => change > 0;
}

class OverspendingAlert {
  final String categoryKey;
  final String displayName;
  final double currentAmount;
  final double previousAmount;
  final double changePercent;

  const OverspendingAlert({
    required this.categoryKey,
    required this.displayName,
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercent,
  });
}

class Rule503020 {
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;

  const Rule503020({
    required this.needsPercent,
    required this.wantsPercent,
    required this.savingsPercent,
  });

  static const needsTarget = 50.0;
  static const wantsTarget = 30.0;
  static const savingsTarget = 20.0;

  double get needsDeviation => (needsPercent - needsTarget).abs();
  double get wantsDeviation => (wantsPercent - wantsTarget).abs();
  double get savingsDeviation => (savingsPercent - savingsTarget).abs();
}

enum RecommendationType { positive, warning, neutral }

class Recommendation {
  final String title;
  final String description;
  final RecommendationType type;

  const Recommendation({
    required this.title,
    required this.description,
    required this.type,
  });
}

class FinancialAnalysis {
  final List<TransactionItem> currentTransactions;
  final List<TransactionItem> previousTransactions;
  final double currentIncome;
  final double currentCost;
  final double previousIncome;
  final double previousCost;
  final Map<String, String> categoryDisplayNames;
  final Map<String, String> categorySections;

  /// Suma de cuotas pactadas que vencen este mes (compromisos en cuotas).
  final double monthlyInstallmentCommitment;

  FinancialAnalysis({
    required this.currentTransactions,
    required this.previousTransactions,
    required this.currentIncome,
    required this.currentCost,
    required this.previousIncome,
    required this.previousCost,
    required this.categoryDisplayNames,
    required this.categorySections,
    this.monthlyInstallmentCommitment = 0,
  });

  bool get hasPreviousData => previousTransactions.isNotEmpty;

  // --- Month-over-Month ---
  double get incomeChange => currentIncome - previousIncome;
  double get incomeChangePercent =>
      previousIncome > 0 ? (incomeChange / previousIncome) * 100 : 0;
  double get costChange => currentCost - previousCost;
  double get costChangePercent =>
      previousCost > 0 ? (costChange / previousCost) * 100 : 0;

  double get currentBalance => currentIncome - currentCost;
  double get previousBalance => previousIncome - previousCost;

  // --- Category Trends ---
  List<CategoryTrend> get categoryTrends {
    final currentByCategory = _groupCostsByCategory(currentTransactions);
    final previousByCategory = _groupCostsByCategory(previousTransactions);

    final allKeys = <String>{
      ...currentByCategory.keys,
      ...previousByCategory.keys,
    };

    final trends = allKeys.map((key) {
      return CategoryTrend(
        categoryKey: key,
        displayName: categoryDisplayNames[key] ?? key,
        currentAmount: currentByCategory[key] ?? 0,
        previousAmount: previousByCategory[key] ?? 0,
      );
    }).toList();

    trends.sort((a, b) => b.currentAmount.compareTo(a.currentAmount));
    return trends;
  }

  // --- Overspending Alerts (>20% increase) ---
  List<OverspendingAlert> get overspendingAlerts {
    return categoryTrends
        .where((t) => t.previousAmount > 0 && t.changePercent > 20)
        .map((t) => OverspendingAlert(
              categoryKey: t.categoryKey,
              displayName: t.displayName,
              currentAmount: t.currentAmount,
              previousAmount: t.previousAmount,
              changePercent: t.changePercent,
            ))
        .toList();
  }

  // --- 50/30/20 Rule ---
  Rule503020 get budgetRule {
    if (currentIncome <= 0) {
      return const Rule503020(
          needsPercent: 0, wantsPercent: 0, savingsPercent: 0);
    }

    final currentCosts = _groupCostsByCategory(currentTransactions);
    double needs = 0;
    double wants = 0;

    for (final entry in currentCosts.entries) {
      final section = categorySections[entry.key] ?? 'extraordinario';
      if (section == 'indispensable') {
        needs += entry.value;
      } else {
        wants += entry.value;
      }
    }

    final savings = currentIncome - currentCost;

    return Rule503020(
      needsPercent: (needs / currentIncome) * 100,
      wantsPercent: (wants / currentIncome) * 100,
      savingsPercent: (savings / currentIncome) * 100,
    );
  }

  // --- Financial Score (0-100) ---
  int get financialScore {
    double score = 0;

    // Savings rate (40 pts max)
    final savingsRate =
        currentIncome > 0 ? (currentBalance / currentIncome) : 0.0;
    score += (savingsRate.clamp(0.0, 0.4) / 0.4) * 40;

    // Budget adherence to 50/30/20 (30 pts max)
    final rule = budgetRule;
    final totalDeviation =
        rule.needsDeviation + rule.wantsDeviation + rule.savingsDeviation;
    final adherenceScore = (1 - (totalDeviation / 100).clamp(0.0, 1.0)) * 30;
    score += adherenceScore;

    // Category balance: no single category > 40% of total cost (15 pts max)
    if (currentCost > 0) {
      final currentCosts = _groupCostsByCategory(currentTransactions);
      final maxCategoryShare = currentCosts.values
          .map((v) => v / currentCost)
          .fold<double>(0, (a, b) => a > b ? a : b);
      score += maxCategoryShare <= 0.4 ? 15 : (1 - maxCategoryShare) * 15;
    } else {
      score += 15;
    }

    // Month-over-month improvement (15 pts max)
    if (hasPreviousData) {
      if (currentBalance > previousBalance) {
        score += 15;
      } else if (currentBalance >= 0) {
        score += 8;
      }
    } else {
      score += currentBalance >= 0 ? 10 : 0;
    }

    return score.round().clamp(0, 100);
  }

  String get scoreLabel {
    final s = financialScore;
    if (s >= 80) return 'Excelente';
    if (s >= 60) return 'Bueno';
    if (s >= 40) return 'Regular';
    return 'Necesita Atencion';
  }

  // --- Annual Savings Projection ---
  double get annualSavingsProjection {
    final monthlySavings = currentBalance;
    final now = DateTime.now();
    final remainingMonths = 12 - now.month;
    return monthlySavings * (remainingMonths + 1);
  }

  // --- Smart Recommendations ---

  static const int _maxRecommendations = 5;
  static const double _savingsTargetRate = 20.0;
  static const double _installmentBurdenLimit = 25.0;
  static const double _categoryConcentrationLimit = 40.0;
  static const double _incomeDropAlertPercent = 10.0;
  static const int _emergencyFundMonths = 3;
  static const int _antExpenseMinCount = 8;

  /// Consejos priorizados: primero las alertas accionables, luego
  /// oportunidades de mejora y al final los refuerzos positivos.
  List<Recommendation> get recommendations {
    final warnings = <Recommendation>[];
    final tips = <Recommendation>[];
    final positives = <Recommendation>[];

    _addBalanceAndSavingsAdvice(warnings, tips, positives);
    _addIncomeDropAdvice(warnings);
    _addOverspendingAdvice(warnings);
    _addInstallmentBurdenAdvice(warnings);
    _addBudgetRuleAdvice(warnings);
    _addCategoryConcentrationAdvice(tips);
    _addAntExpensesAdvice(tips);
    _addImprovementAdvice(positives);

    final result = [...warnings, ...tips, ...positives];
    if (result.isEmpty) {
      result.add(const Recommendation(
        title: 'En camino',
        description:
            'Sigue registrando tus movimientos para obtener recomendaciones mas precisas.',
        type: RecommendationType.neutral,
      ));
    }
    return result.take(_maxRecommendations).toList();
  }

  double get _savingsRate =>
      currentIncome > 0 ? (currentBalance / currentIncome) * 100 : 0.0;

  /// Categoria prescindible (no indispensable) con mayor gasto del mes.
  CategoryTrend? get _topDiscretionaryCategory {
    for (final trend in categoryTrends) {
      final section = categorySections[trend.categoryKey] ?? 'extraordinario';
      if (section != 'indispensable' && trend.currentAmount > 0) return trend;
    }
    return null;
  }

  void _addBalanceAndSavingsAdvice(
    List<Recommendation> warnings,
    List<Recommendation> tips,
    List<Recommendation> positives,
  ) {
    if (currentBalance < 0) {
      final deficit = CurrencyFormatter.format(currentBalance.abs());
      final topWants = _topDiscretionaryCategory;
      final cutHint = topWants != null
          ? ' Tu mayor gasto prescindible es ${topWants.displayName} '
              '(${CurrencyFormatter.format(topWants.currentAmount)}): '
              'es el primer lugar donde recortar.'
          : ' Revisa las categorias con mayor gasto.';
      warnings.add(Recommendation(
        title: 'Gastos superan ingresos',
        description: 'Este mes gastaste $deficit mas de lo que ingresaste.$cutHint',
        type: RecommendationType.warning,
      ));
      return;
    }

    if (currentIncome <= 0) return;

    if (_savingsRate >= _savingsTargetRate) {
      positives.add(Recommendation(
        title: 'Buen ritmo de ahorro',
        description:
            'Estas ahorrando el ${_savingsRate.toStringAsFixed(1)}% de tus ingresos '
            '(${CurrencyFormatter.format(currentBalance)}). Sigue asi.',
        type: RecommendationType.positive,
      ));
      _addEmergencyFundAdvice(tips);
    } else {
      final missing =
          currentIncome * (_savingsTargetRate / 100) - currentBalance;
      warnings.add(Recommendation(
        title: 'Aumenta tu ahorro',
        description:
            'Estas ahorrando el ${_savingsRate.toStringAsFixed(1)}%. Te faltan '
            '${CurrencyFormatter.format(missing)} al mes para llegar al 20% '
            'que recomienda la regla 50/30/20.',
        type: RecommendationType.warning,
      ));
    }
  }

  /// Meta de fondo de emergencia: N meses de gastos indispensables.
  void _addEmergencyFundAdvice(List<Recommendation> tips) {
    final costs = _groupCostsByCategory(currentTransactions);
    double needs = 0;
    for (final entry in costs.entries) {
      if ((categorySections[entry.key] ?? '') == 'indispensable') {
        needs += entry.value;
      }
    }
    if (needs <= 0 || currentBalance <= 0) return;

    final target = needs * _emergencyFundMonths;
    final months = (target / currentBalance).ceil();
    tips.add(Recommendation(
      title: 'Construye tu fondo de emergencia',
      description:
          'Con tus gastos indispensables, un fondo de $_emergencyFundMonths meses '
          'equivale a ${CurrencyFormatter.format(target)}. A tu ritmo actual de '
          'ahorro lo alcanzas en ~$months meses.',
      type: RecommendationType.neutral,
    ));
  }

  void _addIncomeDropAdvice(List<Recommendation> warnings) {
    if (!hasPreviousData || previousIncome <= 0) return;
    if (incomeChangePercent >= -_incomeDropAlertPercent) return;
    warnings.add(Recommendation(
      title:
          'Tus ingresos cayeron ${incomeChangePercent.abs().toStringAsFixed(0)}%',
      description:
          'Ingresaste ${CurrencyFormatter.format(incomeChange.abs())} menos que '
          'el mes pasado. Ajusta tus gastos prescindibles a tu nueva realidad.',
      type: RecommendationType.warning,
    ));
  }

  void _addOverspendingAdvice(List<Recommendation> warnings) {
    for (final alert in overspendingAlerts.take(2)) {
      warnings.add(Recommendation(
        title:
            '${alert.displayName} aumento ${alert.changePercent.toStringAsFixed(0)}%',
        description:
            'Paso de ${CurrencyFormatter.format(alert.previousAmount)} a '
            '${CurrencyFormatter.format(alert.currentAmount)} respecto al mes anterior.',
        type: RecommendationType.warning,
      ));
    }
  }

  void _addInstallmentBurdenAdvice(List<Recommendation> warnings) {
    if (monthlyInstallmentCommitment <= 0 || currentIncome <= 0) return;
    final burden = (monthlyInstallmentCommitment / currentIncome) * 100;
    if (burden <= _installmentBurdenLimit) return;
    warnings.add(Recommendation(
      title: 'Carga de cuotas alta',
      description:
          'Tus cuotas pactadas (${CurrencyFormatter.format(monthlyInstallmentCommitment)}) '
          'consumen el ${burden.toStringAsFixed(0)}% de tus ingresos. Sobre el '
          '${_installmentBurdenLimit.toStringAsFixed(0)}% conviene evitar nuevas compras en cuotas.',
      type: RecommendationType.warning,
    ));
  }

  void _addBudgetRuleAdvice(List<Recommendation> warnings) {
    final rule = budgetRule;
    if (rule.needsPercent > Rule503020.needsTarget + 10) {
      warnings.add(Recommendation(
        title: 'Gastos indispensables muy altos',
        description:
            'Representan el ${rule.needsPercent.toStringAsFixed(1)}% de tus ingresos. '
            'Lo ideal es maximo 50%: renegocia cuentas fijas o busca aumentar ingresos.',
        type: RecommendationType.warning,
      ));
    } else if (rule.wantsPercent > Rule503020.wantsTarget + 10) {
      final topWants = _topDiscretionaryCategory;
      final detail = topWants != null
          ? ' La mayor parte va a ${topWants.displayName} '
              '(${CurrencyFormatter.format(topWants.currentAmount)}).'
          : '';
      warnings.add(Recommendation(
        title: 'Gastos prescindibles sobre el limite',
        description:
            'Tus deseos representan el ${rule.wantsPercent.toStringAsFixed(1)}% '
            'de tus ingresos (ideal: 30%).$detail',
        type: RecommendationType.warning,
      ));
    }
  }

  void _addCategoryConcentrationAdvice(List<Recommendation> tips) {
    if (currentCost <= 0) return;
    final costs = _groupCostsByCategory(currentTransactions);
    String? topKey;
    double topAmount = 0;
    for (final entry in costs.entries) {
      if (entry.value > topAmount) {
        topAmount = entry.value;
        topKey = entry.key;
      }
    }
    if (topKey == null) return;
    final share = (topAmount / currentCost) * 100;
    if (share <= _categoryConcentrationLimit) return;
    tips.add(Recommendation(
      title: 'Gasto concentrado en una categoria',
      description:
          '${categoryDisplayNames[topKey] ?? topKey} concentra el '
          '${share.toStringAsFixed(0)}% de tus gastos '
          '(${CurrencyFormatter.format(topAmount)}). Diversificar te da mas margen de ajuste.',
      type: RecommendationType.neutral,
    ));
  }

  /// Gastos hormiga: muchas compras pequenas que sumadas pesan en el mes.
  void _addAntExpensesAdvice(List<Recommendation> tips) {
    if (currentIncome <= 0) return;
    final smallThreshold = currentIncome * 0.015;
    final smallCosts = currentTransactions
        .where((t) =>
            t.type == 'cost' && t.parentId == null && t.amount <= smallThreshold)
        .toList();
    if (smallCosts.length < _antExpenseMinCount) return;
    final total = smallCosts.fold(0.0, (sum, t) => sum + t.amount);
    if (total < currentIncome * 0.05) return;
    tips.add(Recommendation(
      title: 'Gastos hormiga detectados',
      description:
          '${smallCosts.length} gastos pequenos suman '
          '${CurrencyFormatter.format(total)} este mes '
          '(${((total / currentIncome) * 100).toStringAsFixed(0)}% de tus ingresos). '
          'Son los mas faciles de recortar.',
      type: RecommendationType.neutral,
    ));
  }

  void _addImprovementAdvice(List<Recommendation> positives) {
    if (!hasPreviousData || currentBalance <= previousBalance) return;
    final improvement = currentBalance - previousBalance;
    positives.add(Recommendation(
      title: 'Mejoraste vs el mes anterior',
      description:
          'Tu balance mejoro ${CurrencyFormatter.format(improvement)} respecto '
          'al mes pasado. Buen trabajo.',
      type: RecommendationType.positive,
    ));
  }

  Map<String, double> _groupCostsByCategory(List<TransactionItem> items) {
    final map = <String, double>{};
    for (final t in items) {
      if (t.type != 'cost' || t.parentId != null) continue;
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }
}
