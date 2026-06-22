import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/expense_sections.dart';
import '../../core/constants/onboarding_defaults.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/income_source.dart';
import '../../data/models/payment_method.dart';
import '../../domain/repositories/finance_repository.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final FinanceRepository repository;

  OnboardingBloc({required this.repository}) : super(const OnboardingState()) {
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<ToggleIncomeSource>(_onToggleIncomeSource);
    on<AddCustomIncomeSource>(_onAddCustomIncomeSource);
    on<ToggleExpenseCategory>(_onToggleExpenseCategory);
    on<AddCustomExpenseCategory>(_onAddCustomExpenseCategory);
    on<CompleteOnboarding>(_onCompleteOnboarding);
  }

  void _onNextStep(NextStep event, Emitter<OnboardingState> emit) {
    if (state.currentStep < state.totalSteps - 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void _onPreviousStep(PreviousStep event, Emitter<OnboardingState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  void _onToggleIncomeSource(
      ToggleIncomeSource event, Emitter<OnboardingState> emit) {
    final updated = Set<String>.from(state.selectedIncomeSources);
    if (updated.contains(event.name)) {
      updated.remove(event.name);
    } else {
      updated.add(event.name);
    }
    emit(state.copyWith(selectedIncomeSources: updated));
  }

  void _onAddCustomIncomeSource(
      AddCustomIncomeSource event, Emitter<OnboardingState> emit) {
    final name = event.name.trim();
    if (name.isEmpty) return;
    final updatedCustom = List<String>.from(state.customIncomeSources)
      ..add(name);
    final updatedSelected = Set<String>.from(state.selectedIncomeSources)
      ..add(name);
    emit(state.copyWith(
      customIncomeSources: updatedCustom,
      selectedIncomeSources: updatedSelected,
    ));
  }

  void _onToggleExpenseCategory(
      ToggleExpenseCategory event, Emitter<OnboardingState> emit) {
    final updated = Set<String>.from(state.selectedCategoryKeys);
    if (updated.contains(event.key)) {
      updated.remove(event.key);
    } else {
      updated.add(event.key);
    }
    emit(state.copyWith(selectedCategoryKeys: updated));
  }

  void _onAddCustomExpenseCategory(
      AddCustomExpenseCategory event, Emitter<OnboardingState> emit) {
    final displayName = event.displayName.trim();
    if (displayName.isEmpty) return;
    final key = ExpenseSections.slugify(displayName);
    final updatedCustom = List<Map<String, String>>.from(state.customCategories)
      ..add({
        'key': key,
        'display_name': displayName,
        'section': event.section,
      });
    final updatedSelected = Set<String>.from(state.selectedCategoryKeys)
      ..add(key);
    emit(state.copyWith(
      customCategories: updatedCustom,
      selectedCategoryKeys: updatedSelected,
    ));
  }

  Future<void> _onCompleteOnboarding(
      CompleteOnboarding event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isCompleting: true));
    try {
      for (final name in state.selectedIncomeSources) {
        await repository.addIncomeSource(IncomeSource(name: name));
      }

      await repository
          .addPaymentMethod(PaymentMethod(name: OnboardingDefaults.defaultPaymentMethod));

      final allCategories = <Map<String, String>>[];
      for (final entry in OnboardingDefaults.expenseCategories.entries) {
        for (final cat in entry.value) {
          if (state.selectedCategoryKeys.contains(cat['key'])) {
            allCategories.add({...cat, 'section': entry.key});
          }
        }
      }
      for (final custom in state.customCategories) {
        if (state.selectedCategoryKeys.contains(custom['key'])) {
          allCategories.add(custom);
        }
      }

      for (final cat in allCategories) {
        await repository.addExpenseCategory(ExpenseCategory(
          key: cat['key']!,
          displayName: cat['display_name']!,
          section: cat['section']!,
        ));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      emit(state.copyWith(isCompleting: false, isCompleted: true));
    } catch (e) {
      emit(state.copyWith(isCompleting: false));
    }
  }
}
