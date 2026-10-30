import 'package:flutter/material.dart';

/// Nottia's night-and-moon palette.
///
/// Keep every screen on these tokens so the whole app feels like one sky.
abstract final class AppColors {
  /// Top of the background gradient.
  static const Color midnight = Color(0xFF040414);

  /// Bottom of the background gradient.
  static const Color deepIndigo = Color(0xFF11155B);

  /// Warm paper-white used for the wordmark and moonlit text.
  static const Color moonCream = Color(0xFFF8F3E3);

  /// Slightly deeper cream for moon highlights and secondary copy.
  static const Color moonGold = Color(0xFFE6D7AA);

  /// Tiny star highlights.
  static const Color starWhite = Color(0xFFFFFDF4);

  /// Muted lavender for supporting text on dark surfaces.
  static const Color dustLavender = Color(0xFF9AA0D8);

  /// Grey used for the login field icons and their placeholder text.
  static const Color fieldGrey = Color(0xFFA2A2A2);

  /// Dark ink used for text typed into the white login fields.
  static const Color fieldInk = Color(0xFF3A3A46);

  /// Start of the login button gradient (left).
  static const Color loginBlueStart = Color(0xFF3274D8);

  /// End of the login button gradient (right).
  static const Color loginBlueEnd = Color(0xFF0947A5);

  /// Failure accents for the login form.
  static const Color errorRed = Color(0xFFFF7A7A);

  static const LinearGradient nightSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [midnight, deepIndigo],
  );

  /// Left-to-right gradient for the primary login button.
  static const LinearGradient loginButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [loginBlueStart, loginBlueEnd],
  );
}
