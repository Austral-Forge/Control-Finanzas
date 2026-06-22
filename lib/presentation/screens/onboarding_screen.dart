import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/expense_sections.dart';
import '../../core/constants/onboarding_defaults.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/context_theme_x.dart';
import '../../domain/repositories/finance_repository.dart';
import '../blocs/onboarding_bloc.dart';
import '../blocs/onboarding_event.dart';
import '../blocs/onboarding_state.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final FinanceRepository repository;

  const OnboardingScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(repository: repository),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) =>
          prev.currentStep != curr.currentStep || curr.isCompleted,
      listener: (context, state) {
        if (state.isCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }
        _animateToPage(state.currentStep);
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(state),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomePage(onNext: () => _next(context)),
                      _IncomeSourcesPage(),
                      _ExpenseCategoriesPage(),
                      _SummaryPage(),
                    ],
                  ),
                ),
                if (state.currentStep > 0) _buildBottomBar(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  void _next(BuildContext context) =>
      context.read<OnboardingBloc>().add(NextStep());

  Widget _buildProgressIndicator(OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(state.totalSteps, (i) {
          final isActive = i <= state.currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary
                    : AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, OnboardingState state) {
    final bloc = context.read<OnboardingBloc>();
    final isLast = state.currentStep == state.totalSteps - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => bloc.add(PreviousStep()),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Atras'),
          ),
          const Spacer(),
          if (isLast)
            FilledButton(
              onPressed: state.isCompleting
                  ? null
                  : () => bloc.add(CompleteOnboarding()),
              child: state.isCompleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmar y Empezar'),
            )
          else
            FilledButton.icon(
              onPressed: () => bloc.add(NextStep()),
              icon: const Text('Continuar'),
              label: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 0: Welcome
// ---------------------------------------------------------------------------
class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wallet, size: 64, color: AppTheme.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Bienvenido a\nControl Finanzas',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Lleva el control de tus ingresos, gastos y ahorro '
            'de forma simple. Configuremos juntos tu perfil financiero.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: context.secondaryTextColor),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Text('Comenzar'),
            label: const Icon(Icons.arrow_forward_rounded, size: 18),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 52),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Income Sources
// ---------------------------------------------------------------------------
class _IncomeSourcesPage extends StatelessWidget {
  final _customController = TextEditingController();

  _IncomeSourcesPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final allSources = [
          ...OnboardingDefaults.incomeSources,
          ...state.customIncomeSources,
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          children: [
            Text('Fuentes de Ingreso',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Selecciona las que apliquen a tu situacion',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allSources.map((name) {
                final selected = state.selectedIncomeSources.contains(name);
                return FilterChip(
                  label: Text(name),
                  selected: selected,
                  onSelected: (_) => context
                      .read<OnboardingBloc>()
                      .add(ToggleIncomeSource(name)),
                  selectedColor: AppTheme.income.withValues(alpha: 0.18),
                  checkmarkColor: AppTheme.income,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: 'Agregar fuente personalizada',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final text = _customController.text.trim();
                    if (text.isNotEmpty) {
                      context
                          .read<OnboardingBloc>()
                          .add(AddCustomIncomeSource(text));
                      _customController.clear();
                    }
                  },
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Expense Categories
// ---------------------------------------------------------------------------
class _ExpenseCategoriesPage extends StatelessWidget {
  const _ExpenseCategoriesPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          children: [
            Text('Categorias de Gasto',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Selecciona las categorias que usas habitualmente',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 24),
            for (final section in ExpenseSection.values)
              _buildSectionBlock(context, state, section),
          ],
        );
      },
    );
  }

  Widget _buildSectionBlock(
      BuildContext context, OnboardingState state, ExpenseSection section) {
    final sectionKey = section.name;
    final defaults =
        OnboardingDefaults.expenseCategories[sectionKey] ?? const [];
    final customForSection = state.customCategories
        .where((c) => c['section'] == sectionKey)
        .toList();

    final allCats = [
      ...defaults,
      ...customForSection,
    ];

    final color = ExpenseSections.colorOf(section);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ExpenseSections.getSectionDisplayName(section),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allCats.map((cat) {
              final key = cat['key']!;
              final selected = state.selectedCategoryKeys.contains(key);
              return FilterChip(
                label: Text(cat['display_name']!),
                selected: selected,
                onSelected: (_) => context
                    .read<OnboardingBloc>()
                    .add(ToggleExpenseCategory(key)),
                selectedColor: color.withValues(alpha: 0.18),
                checkmarkColor: color,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          _AddCustomCategoryField(section: sectionKey),
        ],
      ),
    );
  }
}

class _AddCustomCategoryField extends StatefulWidget {
  final String section;
  const _AddCustomCategoryField({required this.section});

  @override
  State<_AddCustomCategoryField> createState() =>
      _AddCustomCategoryFieldState();
}

class _AddCustomCategoryFieldState extends State<_AddCustomCategoryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Agregar categoria',
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              context.read<OnboardingBloc>().add(
                    AddCustomExpenseCategory(
                      displayName: text,
                      section: widget.section,
                    ),
                  );
              _controller.clear();
            }
          },
          icon: const Icon(Icons.add_circle_outline, size: 22),
          color: AppTheme.primary,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Summary
// ---------------------------------------------------------------------------
class _SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final selectedCats = _resolveSelectedCategories(state);

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          children: [
            Text('Resumen de Configuracion',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Revisa tu configuracion antes de empezar',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.secondaryTextColor),
            ),
            const SizedBox(height: 24),
            _SummarySection(
              title: 'Fuentes de Ingreso',
              icon: Icons.trending_up_rounded,
              color: AppTheme.income,
              items: state.selectedIncomeSources.toList(),
              emptyMessage: 'No seleccionaste fuentes de ingreso',
            ),
            const SizedBox(height: 16),
            for (final section in ExpenseSection.values) ...[
              _SummarySection(
                title: ExpenseSections.getSectionDisplayName(section),
                icon: Icons.receipt_long_rounded,
                color: ExpenseSections.colorOf(section),
                items: selectedCats
                    .where((c) => c['section'] == section.name)
                    .map((c) => c['display_name']!)
                    .toList(),
                emptyMessage: 'Sin categorias seleccionadas',
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  List<Map<String, String>> _resolveSelectedCategories(OnboardingState state) {
    final result = <Map<String, String>>[];
    for (final entry in OnboardingDefaults.expenseCategories.entries) {
      for (final cat in entry.value) {
        if (state.selectedCategoryKeys.contains(cat['key'])) {
          result.add({...cat, 'section': entry.key});
        }
      }
    }
    for (final custom in state.customCategories) {
      if (state.selectedCategoryKeys.contains(custom['key'])) {
        result.add(custom);
      }
    }
    return result;
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String emptyMessage;

  const _SummarySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: color)),
              const Spacer(),
              Text('${items.length}',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: context.mutedTextColor)),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(emptyMessage,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: context.mutedTextColor))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items
                  .map((name) => Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: color.withValues(alpha: 0.3)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
