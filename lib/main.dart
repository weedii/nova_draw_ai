import 'package:flutter/material.dart';
import 'core/constants/colors.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NovaDraw AI',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF4DA6FF, {
          50: AppColors.primaryLight,
          100: AppColors.primaryLight,
          200: AppColors.primaryLight,
          300: AppColors.primary,
          400: AppColors.primary,
          500: AppColors.primary,
          600: AppColors.primaryDark,
          700: AppColors.primaryDark,
          800: AppColors.primaryDark,
          900: AppColors.primaryDark,
        }),
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.background,
        ),
      ),

      routerConfig: appRouter,
    );
  }
}
