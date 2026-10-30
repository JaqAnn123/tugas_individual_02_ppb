import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// The first scene of Nottia: a quiet night sky, a placeholder logo,
/// four tiny twinkling stars, and a half moon rising from the bottom edge.
///
/// All artwork lives in `assets/images/` so it can be swapped for the
/// final Figma exports without touching this file.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished, this.completed = false});

  /// Called when the splash is done (auto-advance or tap to continue).
  final VoidCallback? onFinished;

  /// Skips the entrance animation. Used by the preview entrypoint and tests.
  final bool completed;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const List<_StarSpec> _stars = [
    _StarSpec(
      asset: 'assets/images/stars/star_01.png',
      x: 0.130,
      y: 0.175,
      size: 13,
      phase: 0.00,
    ),
    _StarSpec(
      asset: 'assets/images/stars/star_02.png',
      x: 0.875,
      y: 0.115,
      size: 16,
      phase: 0.35,
    ),
    _StarSpec(
      asset: 'assets/images/stars/star_03.png',
      x: 0.215,
      y: 0.345,
      size: 9,
      phase: 0.62,
    ),
    _StarSpec(
      asset: 'assets/images/stars/star_04.png',
      x: 0.840,
      y: 0.270,
      size: 10,
      phase: 0.18,
    ),
  ];

  late final AnimationController _entrance;
  late final AnimationController _ambient;
  Timer? _autoAdvance;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
      value: widget.completed ? 1 : 0,
    );
    if (!widget.completed) {
      _entrance.forward();
    }

    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    if (widget.onFinished != null) {
      _autoAdvance = Timer(const Duration(milliseconds: 3800), _finish);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final _StarSpec star in _stars) {
      precacheImage(AssetImage(star.asset), context);
    }
    precacheImage(const AssetImage('assets/images/logo_nottia.png'), context);
    precacheImage(const AssetImage('assets/images/moon_half.png'), context);
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  void _finish() {
    if (_hasFinished) return;
    _hasFinished = true;
    _autoAdvance?.cancel();
    widget.onFinished?.call();
  }

  double _segment(double t, double begin, double end, Curve curve) {
    final double local = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(local);
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
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: DecoratedBox(
            decoration: const BoxDecoration(gradient: AppColors.nightSky),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size size = constraints.biggest;
                final double width = size.width;
                final double height = size.height;

                // The logo art is portrait (125 x 197); keep that ratio and
                // leave a generous breath between it and the wordmark.
                final double logoWidth = (width * 0.27).clamp(88.0, 132.0);
                final double logoHeight = logoWidth * 197 / 125;
                final double wordmarkSize =
                    (44 * width / 393).clamp(36.0, 50.0);
                final double gap = (height * 0.042).clamp(26.0, 44.0);

                // The moon art is a wide strip (393 x 77) that belongs flush
                // with the bottom edge, never cropped or oversized.
                final double moonWidth = width;
                final double moonHeight = moonWidth * 77 / 393;

                return AnimatedBuilder(
                  animation: Listenable.merge([_entrance, _ambient]),
                  builder: (BuildContext context, Widget? child) {
                    final double t = _entrance.value;
                    final double ambient = _ambient.value;

                    final double moonIn = _segment(
                      t,
                      0.00,
                      0.68,
                      Curves.easeOutQuart,
                    );
                    final double logoIn = _segment(
                      t,
                      0.05,
                      0.52,
                      Curves.easeOutCubic,
                    );
                    final double wordIn = _segment(
                      t,
                      0.24,
                      0.68,
                      Curves.easeOutCubic,
                    );
                    final double starsIn = _segment(
                      t,
                      0.40,
                      0.90,
                      Curves.easeOut,
                    );

                    final double float =
                        math.sin(ambient * 2 * math.pi) * 2.5 * logoIn;

                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // Warm haze where the moon meets the horizon.
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, 0.98),
                                radius: 1.05,
                                colors: <Color>[
                                  AppColors.moonGold.withValues(alpha: 0.12),
                                  AppColors.moonGold.withValues(alpha: 0.04),
                                  Colors.transparent,
                                ],
                                stops: const <double>[0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // A quiet violet halo behind the logo.
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(0, -0.19),
                                radius: 0.62,
                                colors: <Color>[
                                  const Color(0xFF6D77D8)
                                      .withValues(alpha: 0.13),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Half moon placeholder, resting on the bottom edge.
                        // The translate only slides it IN from below during the
                        // entrance animation; once moonIn == 1, offset is 0.
                        Positioned(
                          left: (width - moonWidth) / 2,
                          bottom: 0,
                          child: Opacity(
                            opacity: moonIn,
                            child: Transform.translate(
                              offset: Offset(0, moonHeight * (1 - moonIn)),
                              child: Image.asset(
                                'assets/images/moon_half.png',
                                width: moonWidth,
                                height: moonHeight,
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                        ),

                        // The four tiny stars.
                        for (final _StarSpec star in _stars)
                          _buildStar(star, starsIn, ambient),

                        // Logo + wordmark — moved higher for more breathing
                        // room between them and the moon.
                        Align(
                          alignment: const Alignment(0, -0.35),
                          child: Transform.translate(
                            offset: Offset(0, float),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Opacity(
                                  opacity: logoIn,
                                  child: Transform.translate(
                                    offset: Offset(0, 18 * (1 - logoIn)),
                                    child: Transform.scale(
                                      scale: 0.90 + 0.10 * logoIn,
                                      child: SizedBox(
                                        width: logoWidth,
                                        height: logoHeight,
                                        child: Image.asset(
                                          'assets/images/logo_nottia.png',
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: gap),
                                Opacity(
                                  opacity: wordIn,
                                  child: Transform.translate(
                                    offset: Offset(0, 22 * (1 - wordIn)),
                                    child: Text(
                                      'nottia',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Caudex',
                                        fontSize: wordmarkSize,
                                        height: 1.0,
                                        letterSpacing: wordmarkSize * 0.045,
                                        color: AppColors.moonCream,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: AppColors.moonCream
                                                .withValues(alpha: 0.28),
                                            blurRadius: 24,
                                          ),
                                          Shadow(
                                            color: const Color(0xFF6C74D8)
                                                .withValues(alpha: 0.30),
                                            blurRadius: 48,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStar(_StarSpec star, double gate, double ambient) {
    final double wave =
        0.5 + 0.5 * math.sin((ambient + star.phase) * 2 * math.pi);
    final double opacity = (gate * (0.55 + 0.45 * wave)).clamp(0.0, 1.0);
    final double scale = 0.88 + 0.24 * wave;

    return Positioned(
      left: star.x * MediaQuery.sizeOf(context).width - star.size / 2,
      top: star.y * MediaQuery.sizeOf(context).height - star.size / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Image.asset(
              star.asset,
              width: star.size,
              height: star.size,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarSpec {
  const _StarSpec({
    required this.asset,
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
  });

  /// Fraction of the screen width.
  final double x;

  /// Fraction of the screen height.
  final double y;
  final String asset;
  final double size;
  final double phase;
}
