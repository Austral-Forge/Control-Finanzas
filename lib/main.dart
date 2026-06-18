import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'presentation/blocs/finance_bloc.dart';
import 'presentation/blocs/settings_bloc.dart';
import 'presentation/blocs/settings_event.dart';
import 'presentation/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);

  final financeRepository = FinanceRepositoryImpl();

  runApp(MyApp(financeRepository: financeRepository));
}

class MyApp extends StatelessWidget {
  final FinanceRepositoryImpl financeRepository;

  const MyApp({super.key, required this.financeRepository});

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
      ],
      child: MaterialApp(
        title: 'Mis Finanzas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      ),
    );
  }
}
