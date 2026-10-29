import 'package:flutter/material.dart';
import 'package:sadeem_ui/sadeem_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/auth/presentation/screens/driver_auth_gate.dart';
import 'features/home/presentation/cubit/driver_home_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeModeController.instance.load();
  runApp(const WingsDriverApp());
}

class WingsDriverApp extends StatelessWidget {
  const WingsDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DriverHomeCubit>(create: (_) => DriverHomeCubit()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeModeController.instance,
        builder: (context, mode, _) => MaterialApp(
          title: 'كابتن سديم',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          locale: SadeemLocale.locale,
          supportedLocales: SadeemLocale.supportedLocales,
          localizationsDelegates: SadeemLocale.delegates,
          home: const DriverAuthGate(),
        ),
      ),
    );
  }
}
