abstract class OnboardingEvent {}

class NextStep extends OnboardingEvent {}

class PreviousStep extends OnboardingEvent {}

class ToggleIncomeSource extends OnboardingEvent {
  final String name;
  ToggleIncomeSource(this.name);
}

class AddCustomIncomeSource extends OnboardingEvent {
  final String name;
  AddCustomIncomeSource(this.name);
}

class ToggleExpenseCategory extends OnboardingEvent {
  final String key;
  ToggleExpenseCategory(this.key);
}

class AddCustomExpenseCategory extends OnboardingEvent {
  final String displayName;
  final String section;
  AddCustomExpenseCategory({required this.displayName, required this.section});
}

class CompleteOnboarding extends OnboardingEvent {}
