// Preview-only entrypoint: shows the login screen without the splash.
// Run with: flutter run -d chrome -t tool/login_preview.dart
import 'package:flutter/material.dart';
import 'package:nottia/core/theme/app_theme.dart';
import 'package:nottia/features/auth/login_page.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    home: LoginScreen(onLoggedIn: (String email) {}),
  ),
);
