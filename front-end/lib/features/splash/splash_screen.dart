import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _textOpacity = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulseScale = Tween(begin: 0.85, end: 1.45)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.restoreSession();

    if (!mounted) return;
    if (auth.isLoggedIn) {
      if (auth.isDermatologue) {
        context.go('/doctor-dashboard');
      } else {
        context.go('/dashboard');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradStart, AppColors.gradMid, AppColors.gradEnd],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Cercles décoratifs
            const Positioned(
              top: -80,
              right: -80,
              child: _Circle(180, AppColors.primaryLight, 0.07),
            ),
            const Positioned(
              top: 60,
              left: -40,
              child: _Circle(120, AppColors.accent, 0.06),
            ),
            const Positioned(
              bottom: 100,
              right: -50,
              child: _Circle(160, AppColors.primary, 0.05),
            ),
            // Contenu principal
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Logo animé
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoCtrl, _pulseCtrl]),
                    builder: (_, __) => SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(alignment: Alignment.center, children: [
                        // Anneau pulsant extérieur
                        Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary
                                    .withOpacity(_pulseOpacity.value),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Anneau pulsant intérieur
                        Transform.scale(
                          scale: (_pulseScale.value + 0.85) / 2,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent
                                    .withOpacity(_pulseOpacity.value * 0.5),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Logo
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bgWhite,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const _LogoWidget(),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Nom de l'app
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(children: [
                        RichText(
                          text: const TextSpan(
                            style: AppFonts.appName,
                            children: [
                              TextSpan(
                                  text: 'Derma',
                                  style: TextStyle(color: AppColors.primary)),
                              TextSpan(
                                  text: 'Scan ',
                                  style:
                                      TextStyle(color: AppColors.primaryDark)),
                              TextSpan(
                                  text: 'AI',
                                  style: TextStyle(color: AppColors.accent)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'INTELLIGENT SKIN MONITORING',
                          style: AppFonts.appSubtitle,
                        ),
                      ]),
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Barre de chargement
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Initialisation…',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: AppColors.textHint,
                            letterSpacing: 0.5,
                          )),
                    ]),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cercle décoratif ──────────────────────────────────────────
class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const _Circle(this.size, this.color, this.opacity);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(opacity),
        ),
      );
}

// ── Logo CustomPaint ──────────────────────────────────────────
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(64, 64), painter: _LogoPainter());
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // Couche de peau (ellipse)
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 46, height: 30),
      Paint()..color = AppColors.primaryLight.withOpacity(0.15),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c, width: 46, height: 30),
      Paint()
        ..color = AppColors.primaryLight.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Lignes de scan IA
    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 1.0;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(c.dx - 17, c.dy + i * 4.5),
        Offset(c.dx + 17, c.dy + i * 4.5),
        linePaint,
      );
    }

    // Point central (lésion)
    canvas.drawCircle(c, 5, Paint()..color = AppColors.primary);

    // Coins de circuit
    final cp = Paint()
      ..color = AppColors.accent.withOpacity(0.8)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _corner(canvas, c, -24, -10, -24, -18, -16, -18, cp);
    _corner(canvas, c, 24, -10, 24, -18, 16, -18, cp);
    _corner(canvas, c, -24, 10, -24, 18, -16, 18, cp);
    _corner(canvas, c, 24, 10, 24, 18, 16, 18, cp);
  }

  void _corner(Canvas canvas, Offset c, double x1, double y1, double x2,
      double y2, double x3, double y3, Paint p) {
    canvas.drawLine(c.translate(x1, y1), c.translate(x2, y2), p);
    canvas.drawLine(c.translate(x2, y2), c.translate(x3, y3), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
