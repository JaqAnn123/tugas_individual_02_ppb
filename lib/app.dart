import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/homepage.dart';
import 'features/splash/splash_page.dart';

class NottiaApp extends StatelessWidget {
  const NottiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nottia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _NottiaFlow(),
    );
  }
}

enum _Stage { splash, login, home }

/// Splash → login → beranda, cross-fading between stages so the night sky
/// never cuts. Replace this gate with real routing once more screens exist.
class _NottiaFlow extends StatefulWidget {
  const _NottiaFlow();

  @override
  State<_NottiaFlow> createState() => _NottiaFlowState();
}

class _NottiaFlowState extends State<_NottiaFlow> {
  _Stage _stage = _Stage.splash;
  String _email = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      child: switch (_stage) {
        _Stage.splash => SplashScreen(
          key: const ValueKey<String>('splash'),
          onFinished: () => setState(() => _stage = _Stage.login),
        ),
        _Stage.login => LoginScreen(
          key: const ValueKey<String>('login'),
          onLoggedIn: (String email) => setState(() {
            _email = email;
            _stage = _Stage.home;
          }),
        ),
        _Stage.home => HomeScreen(
          key: const ValueKey<String>('home'),
          email: _email,
          onLogout: () => setState(() => _stage = _Stage.login),
        ),
      },
    );
  }
}
