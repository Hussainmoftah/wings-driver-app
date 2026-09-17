import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/driver_auth_gate.dart';
import 'features/home/presentation/cubit/driver_home_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WingsDriverApp());
}

class WingsDriverApp extends StatelessWidget {
  const WingsDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DriverHomeCubit>(
          create: (_) => DriverHomeCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Wings Driver | كابتن وينجز',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar', 'LY'),
        supportedLocales: const [
          Locale('ar', 'LY'),
          Locale('ar', ''),
          Locale('en', ''),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const DriverAuthGate(),
      ),
    );
  }
}
