import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/home/presentation/home_page.dart';

void main() {
  runApp(const KosmoApp());
}

class KosmoApp extends StatelessWidget {
  const KosmoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KOSMO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        fontFamily:
            'Inter', // Default to Inter if added to pubspec, otherwise falls back gracefully
      ),
      home: const HomePage(),
    );
  }
}
