import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/database/db_helper.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'data/services/app_lock_service.dart';
import 'presentation/blocs/finance_bloc.dart';
import 'presentation/blocs/settings_bloc.dart';
import 'presentation/blocs/settings_event.dart';
import 'presentation/blocs/theme_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/lock_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);

  final prefs = await SharedPreferences.getInstance();
  var onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  if (!onboardingCompleted) {
    final summaries = await FinanceRepositoryImpl().getMonthlySummaries();
    if (summaries.isNotEmpty) {
      onboardingCompleted = true;
      await prefs.setBool('onboarding_completed', true);
    }
  }

  DbHelper.skipSampleSeeding = !onboardingCompleted;

  final financeRepository = FinanceRepositoryImpl();
  final lockService = AppLockService();
  final lockEnabled = await lockService.isEnabled();

  runApp(MyApp(
    financeRepository: financeRepository,
    onboardingCompleted: onboardingCompleted,
    lockService: lockService,
    lockEnabled: lockEnabled,
  ));
}

class MyApp extends StatelessWidget {
  final FinanceRepositoryImpl financeRepository;
  final bool onboardingCompleted;
  final AppLockService lockService;
  final bool lockEnabled;

  const MyApp({
    super.key,
    required this.financeRepository,
    required this.onboardingCompleted,
    required this.lockService,
    required this.lockEnabled,
  });

  Widget get _home {
    if (!onboardingCompleted) {
      return OnboardingScreen(repository: financeRepository);
    }
    if (lockEnabled) return LockScreen(lockService: lockService);
    return const HomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => FinanceBloc(financeRepository: financeRepository),
        ),
        BlocProvider(
          create: (_) =>
              SettingsBloc(financeRepository: financeRepository)..add(LoadSettings()),
        ),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Control Finanzas Card',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: _home,
          );
        },
      ),
    );
  }
}
