// Preview-only entrypoint: shows the splash screen without auto-advancing.
// Run with: flutter run -d chrome -t tool/splash_preview.dart
import 'package:flutter/material.dart';
import 'package:nottia/core/theme/app_theme.dart';
import 'package:nottia/features/splash/splash_page.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: const SplashScreen(completed: true),
  ),
);
