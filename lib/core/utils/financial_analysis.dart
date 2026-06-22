import '../../data/models/transaction_item.dart';

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

  FinancialAnalysis({
    required this.currentTransactions,
    required this.previousTransactions,
    required this.currentIncome,
    required this.currentCost,
    required this.previousIncome,
    required this.previousCost,
    required this.categoryDisplayNames,
    required this.categorySections,
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
  List<Recommendation> get recommendations {
    final result = <Recommendation>[];
    final savingsRate =
        currentIncome > 0 ? (currentBalance / currentIncome) * 100 : 0.0;

    if (savingsRate >= 20) {
      result.add(Recommendation(
        title: 'Buen ritmo de ahorro',
        description:
            'Estas ahorrando el ${savingsRate.toStringAsFixed(1)}% de tus ingresos. Sigue asi.',
        type: RecommendationType.positive,
      ));
    } else if (savingsRate > 0) {
      result.add(Recommendation(
        title: 'Aumenta tu ahorro',
        description:
            'Solo estas ahorrando el ${savingsRate.toStringAsFixed(1)}%. '
            'La regla 50/30/20 recomienda al menos un 20%.',
        type: RecommendationType.warning,
      ));
    } else if (currentBalance < 0) {
      result.add(Recommendation(
        title: 'Gastos superan ingresos',
        description:
            'Este mes gastaste mas de lo que ingresaste. Revisa las categorias con mayor gasto.',
        type: RecommendationType.warning,
      ));
    }

    for (final alert in overspendingAlerts.take(2)) {
      result.add(Recommendation(
        title: '${alert.displayName} aumento ${alert.changePercent.toStringAsFixed(0)}%',
        description:
            'Paso de \$${alert.previousAmount.toStringAsFixed(0)} a '
            '\$${alert.currentAmount.toStringAsFixed(0)} respecto al mes anterior.',
        type: RecommendationType.warning,
      ));
    }

    final rule = budgetRule;
    if (rule.needsPercent > 60) {
      result.add(Recommendation(
        title: 'Gastos indispensables muy altos',
        description:
            'Representan el ${rule.needsPercent.toStringAsFixed(1)}% de tus ingresos. '
            'Lo ideal es maximo 50%.',
        type: RecommendationType.warning,
      ));
    }

    if (hasPreviousData && currentBalance > previousBalance) {
      result.add(const Recommendation(
        title: 'Mejoraste vs el mes anterior',
        description: 'Tu balance mejoro respecto al mes pasado. Buen trabajo.',
        type: RecommendationType.positive,
      ));
    }

    if (result.isEmpty) {
      result.add(const Recommendation(
        title: 'En camino',
        description:
            'Sigue registrando tus movimientos para obtener recomendaciones mas precisas.',
        type: RecommendationType.neutral,
      ));
    }

    return result;
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
