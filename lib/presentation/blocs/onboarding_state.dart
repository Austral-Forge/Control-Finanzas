class OnboardingState {
  final int currentStep;
  final Set<String> selectedIncomeSources;
  final List<String> customIncomeSources;
  final Set<String> selectedCategoryKeys;
  final List<Map<String, String>> customCategories;
  final bool isCompleting;
  final bool isCompleted;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedIncomeSources = const {},
    this.customIncomeSources = const [],
    this.selectedCategoryKeys = const {},
    this.customCategories = const [],
    this.isCompleting = false,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    Set<String>? selectedIncomeSources,
    List<String>? customIncomeSources,
    Set<String>? selectedCategoryKeys,
    List<Map<String, String>>? customCategories,
    bool? isCompleting,
    bool? isCompleted,
  }) =>
      OnboardingState(
        currentStep: currentStep ?? this.currentStep,
        selectedIncomeSources:
            selectedIncomeSources ?? this.selectedIncomeSources,
        customIncomeSources: customIncomeSources ?? this.customIncomeSources,
        selectedCategoryKeys:
            selectedCategoryKeys ?? this.selectedCategoryKeys,
        customCategories: customCategories ?? this.customCategories,
        isCompleting: isCompleting ?? this.isCompleting,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  int get totalSteps => 4;
}
