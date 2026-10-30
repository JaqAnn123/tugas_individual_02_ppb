import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// The Nottia sign-in screen.
///
/// Small brand lockup at the top, a 270 px form in the middle of the page,
/// and a quiet moon resting on the bottom edge. Credentials are checked
/// locally; the real backend will replace [_demoEmail] / [_demoPassword].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});

  /// Called with the signed-in email once the local check passes.
  final ValueChanged<String> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const String _demoEmail = 'anngelicaaa00@gmail.com';
  static const String _demoPassword = '12345678';

  static const String _fontFamily = 'MontserratAlternates';

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  late final AnimationController _shake;
  bool _isSubmitting = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _clearError(String _) {
    if (!_hasError) return;
    setState(() => _hasError = false);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final String email = _email.text.trim();
    final String password = _password.text;
    final bool isComplete = email.isNotEmpty && password.isNotEmpty;
    final bool isValid =
        email.toLowerCase() == _demoEmail && password == _demoPassword;

    setState(() {
      _isSubmitting = true;
      _hasError = false;
    });

    // A short beat so the loading state is readable instead of a flicker.
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;

    if (isValid) {
      setState(() => _isSubmitting = false);
      widget.onLoggedIn(email);
      return;
    }

    setState(() {
      _isSubmitting = false;
      _hasError = true;
    });
    _shake.forward(from: 0);
    _showMessage(
      isComplete ? 'email atau password salah' : 'isi email dan password dulu',
    );
  }

  void _loginWithGoogle() {
    FocusScope.of(context).unfocus();
    _showMessage('login dengan google belum tersedia');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 22),
          backgroundColor: const Color(0xFF1B1F4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13,
              height: 1.4,
              color: AppColors.moonCream,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.nightSky),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // A soft violet halo behind the form so the white boxes float.
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.05),
                      radius: 0.75,
                      colors: <Color>[
                        const Color(0xFF6D77D8).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // The moon stays only along the bottom edge, dimmed so the
              // form keeps focus.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.16,
                    child: Image.asset(
                      'assets/images/moon_half.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // The form sits in the exact center of the page.
                        SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 120,
                                ),
                                child: _buildForm(),
                              ),
                            ),
                          ),
                        ),

                        // Small brand lockup, a little above the top edge.
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 26),
                            child: _buildBrand(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Image.asset(
          'assets/images/logo_nottia.png',
          width: 36,
          height: 36 * 197 / 125,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 8),
        Text(
          'nottia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Caudex',
            fontSize: 20,
            height: 1,
            letterSpacing: 1.0,
            color: AppColors.moonCream,
            shadows: <Shadow>[
              Shadow(
                color: AppColors.moonCream.withValues(alpha: 0.28),
                blurRadius: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return AnimatedBuilder(
      animation: _shake,
      builder: (BuildContext context, Widget? child) {
        final double t = _shake.value;
        final double dx = math.sin(t * math.pi * 5) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: SizedBox(
        width: 270,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'login to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0.2,
                color: AppColors.moonCream,
              ),
            ),
            const SizedBox(height: 26),

            _buildField(
              controller: _email,
              hint: 'email',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 19),

            _buildField(
              controller: _password,
              focusNode: _passwordFocus,
              hint: 'password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 38),

            _buildLoginButton(),
            const SizedBox(height: 26),

            _buildDivider(),
            const SizedBox(height: 22),

            _buildGoogleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    FocusNode? focusNode,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      height: 37,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: _hasError ? AppColors.errorRed : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 13),
          Icon(icon, size: 17, color: AppColors.fieldGrey),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              autofillHints: autofillHints,
              onSubmitted: onSubmitted,
              onChanged: _clearError,
              cursorColor: AppColors.loginBlueEnd,
              cursorWidth: 1.4,
              style: const TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.1,
                color: AppColors.fieldInk,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.fieldGrey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 37,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.loginButton,
          borderRadius: BorderRadius.circular(9),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.loginBlueEnd.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: _isSubmitting ? null : _submit,
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'login',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    final Color lineColor = Colors.white.withValues(alpha: 0.45);
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(height: 1, thickness: 1, color: lineColor),
        ),
        const SizedBox(width: 14),
        Text(
          'or',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1,
            color: AppColors.moonCream.withValues(alpha: 0.82),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Divider(height: 1, thickness: 1, color: lineColor),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      height: 37,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _loginWithGoogle,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Image.asset(
                    'assets/images/google_g.png',
                    width: 18,
                    height: 18,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'login with google',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1,
                      color: Color(0xFF55555F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
