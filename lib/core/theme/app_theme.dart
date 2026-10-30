import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B84E8),
      brightness: Brightness.dark,
      surface: AppColors.midnight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.midnight,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: 'Caudex',
          fontSize: 40,
          height: 1.1,
          color: AppColors.moonCream,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Caudex',
          fontSize: 28,
          height: 1.2,
          color: AppColors.moonCream,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppColors.dustLavender,
        ),
      ),
    );
  }
}
