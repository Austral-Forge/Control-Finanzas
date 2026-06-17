import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/finance_repository.dart';
import 'data/repositories/finance_repository_impl.dart';
import 'presentation/blocs/finance_bloc.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  // Asegurar la inicialización de los bindings de Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar localización para formateo de fechas en español
  await initializeDateFormatting('es_CL', null);

  // Crear la implementación del repositorio
  final financeRepository = FinanceRepositoryImpl();

  runApp(
    MyApp(financeRepository: financeRepository),
  );
}

class MyApp extends StatelessWidget {
  final FinanceRepository financeRepository;

  const MyApp({
    super.key,
    required this.financeRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FinanceBloc(financeRepository: financeRepository),
      child: MaterialApp(
        title: 'Mis Finanzas 2026',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
