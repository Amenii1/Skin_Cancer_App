import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'onboarding_provider.dart';
import 'onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: _Body(ctrl: _ctrl),
    );
  }
}

// ── Corps principal ───────────────────────────────────────────
class _Body extends StatelessWidget {
  final PageController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OnboardingProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.gradStart, AppColors.gradEnd],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // Top bar
            _TopBar(prov: prov),
            // Pages
            Expanded(
              child: PageView.builder(
                controller: ctrl,
                onPageChanged: prov.onChanged,
                itemCount: kOnboardingItems.length,
                itemBuilder: (_, i) =>
                    _PageContent(item: kOnboardingItems[i], index: i),
              ),
            ),
            // Bottom controls
            _BottomBar(prov: prov, ctrl: ctrl),
            const SizedBox(height: 36),
          ]),
        ),
      ),
    );
  }
}

// ── Barre supérieure ─────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final OnboardingProvider prov;
  const _TopBar({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${prov.page + 1} / ${OnboardingProvider.total}',
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textHint,
            ),
          ),
          if (!prov.isLast)
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Passer',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    )),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Contenu d'une page ────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final OnboardingItem item;
  final int index;
  const _PageContent({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        const SizedBox(height: 16),
        // Badge tag
        _TagBadge(label: item.tag),
        const SizedBox(height: 20),
        // Illustration
        Expanded(
          flex: 5,
          child: _Illustration(index: index),
        ),
        const SizedBox(height: 28),
        // Titre
        Text(item.title,
            textAlign: TextAlign.center,
            style: AppFonts.displayMedium),
        const SizedBox(height: 14),
        // Description
        Text(item.description,
            textAlign: TextAlign.center,
            style: AppFonts.bodyLarge),
        const SizedBox(height: 20),
      ]),
    );
  }
}

// ── Badge tag ─────────────────────────────────────────────────
class _TagBadge extends StatelessWidget {
  final String label;
  const _TagBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(
            shape: BoxShape.circle, color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              fontWeight: FontWeight.w700, color: AppColors.primary,
              letterSpacing: 0.5,
            )),
      ]),
    );
  }
}

// ── Barre inférieure ──────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final OnboardingProvider prov;
  final PageController ctrl;
  const _BottomBar({required this.prov, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            OnboardingProvider.total,
            (i) => _Dot(
              active: i == prov.page,
              onTap: () => prov.jumpTo(i, ctrl),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Bouton
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: prov.isLast
              ? _GradientBtn(
                  key: const ValueKey('start'),
                  label: 'Commencer',
                  icon: Icons.rocket_launch_rounded,
                  onTap: () => context.go('/login'),
                )
              : _GradientBtn(
                  key: const ValueKey('next'),
                  label: 'Suivant',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => prov.next(ctrl),
                  solid: true,
                ),
        ),
      ]),
    );
  }
}

// ── Bouton CTA ────────────────────────────────────────────────
class _GradientBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool solid;

  const _GradientBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: solid
              ? null
              : const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: solid ? AppColors.primary : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.32),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppFonts.labelBtn),
            const SizedBox(width: 8),
            Icon(icon, color: AppColors.textWhite, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _Dot({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? AppColors.dotActive : AppColors.dotInactive,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ILLUSTRATIONS (CustomPaint — pas besoin d'assets)
// ══════════════════════════════════════════════════════════════
class _Illustration extends StatefulWidget {
  final int index;
  const _Illustration({required this.index});

  @override
  State<_Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<_Illustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, double.infinity),
        painter: _painters(widget.index, _ctrl.value),
      ),
    );
  }

  CustomPainter _painters(int i, double t) {
    switch (i) {
      case 0: return _ScanPainter(t);
      case 1: return _TrackPainter(t);
      default: return _MapPainter(t);
    }
  }
}

// ── Page 1 : Smartphone + scan ────────────────────────────────
class _ScanPainter extends CustomPainter {
  final double t;
  _ScanPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Fond cercle doux
    canvas.drawCircle(Offset(cx, cy), size.width * 0.40,
        Paint()..color = AppColors.primary.withOpacity(0.06));

    // Ombre téléphone
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: 112, height: 182),
          const Radius.circular(22)),
      Paint()
        ..color = AppColors.primary.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Corps téléphone
    final phoneRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 112, height: 182),
        const Radius.circular(22));
    canvas.drawRRect(phoneRRect,
        Paint()..color = AppColors.bgWhite);
    canvas.drawRRect(phoneRRect,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Écran
    final screenRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 4), width: 90, height: 148),
        const Radius.circular(12));
    canvas.drawRRect(screenRRect,
        Paint()..color = AppColors.bgSoft);

    // Texture peau sur l'écran
    final skinPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + 4),
            width: i * 18.0, height: i * 11.0),
        skinPaint,
      );
    }

    // Grain de beauté (lésion)
    canvas.drawCircle(Offset(cx, cy + 4), 6.5,
        Paint()..color = AppColors.primaryDark.withOpacity(0.55));

    // Ligne de scan animée
    final ease = _ease(t);
    final scanY = (cy - 62) + 124 * ease;
    if (scanY > cy - 72 && scanY < cy + 76) {
      canvas.drawLine(Offset(cx - 42, scanY), Offset(cx + 42, scanY),
          Paint()
            ..color = AppColors.accent.withOpacity(0.22)
            ..strokeWidth = 8);
      canvas.drawLine(Offset(cx - 42, scanY), Offset(cx + 42, scanY),
          Paint()
            ..color = AppColors.accent
            ..strokeWidth = 1.8);
    }

    // Coins de cadrage
    _drawBrackets(canvas, Offset(cx, cy + 4), 42, 70);

    // Encoche
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 84), width: 28, height: 7),
          const Radius.circular(4)),
      Paint()..color = AppColors.border,
    );

    // Badge IA flottant
    final badgeY = cy - 22 + 6 * math.sin(t * math.pi * 2);
    _drawBadge(canvas, Offset(cx + 70, badgeY), '✦ IA');
  }

  void _drawBrackets(Canvas canvas, Offset center, double hw, double hh) {
    const len = 12.0;
    final p = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // top-left
    canvas.drawLine(Offset(center.dx - hw, center.dy - hh),
        Offset(center.dx - hw + len, center.dy - hh), p);
    canvas.drawLine(Offset(center.dx - hw, center.dy - hh),
        Offset(center.dx - hw, center.dy - hh + len), p);
    // top-right
    canvas.drawLine(Offset(center.dx + hw, center.dy - hh),
        Offset(center.dx + hw - len, center.dy - hh), p);
    canvas.drawLine(Offset(center.dx + hw, center.dy - hh),
        Offset(center.dx + hw, center.dy - hh + len), p);
    // bottom-left
    canvas.drawLine(Offset(center.dx - hw, center.dy + hh),
        Offset(center.dx - hw + len, center.dy + hh), p);
    canvas.drawLine(Offset(center.dx - hw, center.dy + hh),
        Offset(center.dx - hw, center.dy + hh - len), p);
    // bottom-right
    canvas.drawLine(Offset(center.dx + hw, center.dy + hh),
        Offset(center.dx + hw - len, center.dy + hh), p);
    canvas.drawLine(Offset(center.dx + hw, center.dy + hh),
        Offset(center.dx + hw, center.dy + hh - len), p);
  }

  void _drawBadge(Canvas canvas, Offset c, String text) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 58, height: 26),
          const Radius.circular(13)),
      Paint()
        ..color = AppColors.primary.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 58, height: 26),
          const Radius.circular(13)),
      Paint()..color = AppColors.primary,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: Colors.white, letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  double _ease(double t) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}

// ── Page 2 : Timeline suivi ───────────────────────────────────
class _TrackPainter extends CustomPainter {
  final double t;
  _TrackPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Fond ovale
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * 0.88,
          height: size.height * 0.62),
      Paint()..color = AppColors.accent.withOpacity(0.06),
    );

    // Ligne de timeline
    canvas.drawLine(
      Offset(cx - 118, cy + 22),
      Offset(cx + 118, cy + 22),
      Paint()..color = AppColors.border..strokeWidth = 2,
    );

    final xs = [cx - 88.0, cx + 0.0, cx + 88.0];
    final labels = ['Jan', 'Avr', 'Juil'];
    final colors = [AppColors.riskLow, AppColors.riskMedium, AppColors.riskHigh];

    for (int i = 0; i < 3; i++) {
      final x = xs[i];
      final float = i == 1 ? 7.0 * math.sin(t * math.pi * 2) : 0.0;
      final cardCenter = Offset(x, cy - 52 + float);

      // Carte
      _drawCard(canvas, cardCenter, colors[i]);

      // Tige
      canvas.drawLine(
        Offset(x, cardCenter.dy + 30),
        Offset(x, cy + 15),
        Paint()
          ..color = colors[i].withOpacity(0.3)
          ..strokeWidth = 1.5,
      );

      // Dot timeline
      canvas.drawCircle(Offset(x, cy + 22), 7,
          Paint()..color = colors[i]);
      canvas.drawCircle(Offset(x, cy + 22), 10,
          Paint()
            ..color = colors[i].withOpacity(0.22)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);

      // Label date
      _text(canvas, Offset(x, cy + 40), labels[i], 11,
          AppColors.textHint, FontWeight.w600);
    }
  }

  void _drawCard(Canvas canvas, Offset center, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 64, height: 54),
          const Radius.circular(12)),
      Paint()
        ..color = AppColors.primary.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 64, height: 54),
          const Radius.circular(12)),
      Paint()..color = AppColors.bgWhite,
    );
    // Barre colorée haut
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 28, center.dy - 25, 56, 4),
          const Radius.circular(2)),
      Paint()..color = color,
    );
    // Lignes de peau
    final lp = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 1.4;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(center.dx - 18, center.dy - 5 + i * 8.0),
        Offset(center.dx + 18, center.dy - 5 + i * 8.0),
        lp,
      );
    }
    // Lésion
    canvas.drawCircle(
        center.translate(0, 3), 5, Paint()..color = color.withOpacity(0.45));
  }

  void _text(Canvas canvas, Offset pos, String txt, double fs,
      Color color, FontWeight fw) {
    final tp = TextPainter(
      text: TextSpan(
          text: txt,
          style: TextStyle(
              fontSize: fs, fontWeight: fw,
              color: color, fontFamily: 'Nunito')),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_TrackPainter old) => old.t != t;
}

// ── Page 3 : Carte + dermatologue ─────────────────────────────
class _MapPainter extends CustomPainter {
  final double t;
  _MapPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Fond carte
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, cy - 12),
              width: size.width * 0.84,
              height: size.height * 0.62),
          const Radius.circular(20)),
      Paint()..color = AppColors.bgSoft,
    );

    // Grille
    final gp = Paint()
      ..color = AppColors.border.withOpacity(0.55)
      ..strokeWidth = 0.7;
    for (int i = -3; i <= 3; i++) {
      canvas.drawLine(Offset(cx - 138, cy + i * 24.0 - 12),
          Offset(cx + 138, cy + i * 24.0 - 12), gp);
      canvas.drawLine(Offset(cx + i * 38.0, cy - 88),
          Offset(cx + i * 38.0, cy + 68), gp);
    }

    // Routes
    final rp = Paint()
      ..color = AppColors.bgWhite
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 138, cy - 12), Offset(cx + 138, cy - 12), rp);
    canvas.drawLine(Offset(cx, cy - 88), Offset(cx, cy + 68), rp);

    // Cercle de proximité
    final pulse = 4 * math.sin(t * math.pi * 2);
    canvas.drawCircle(
      Offset(cx - 48, cy - 38),
      38 + pulse,
      Paint()
        ..color = AppColors.primary.withOpacity(0.07 + 0.03 * math.sin(t * math.pi * 2)),
    );
    canvas.drawCircle(
      Offset(cx - 48, cy - 38),
      38 + pulse,
      Paint()
        ..color = AppColors.primary.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Pins
    _drawPin(canvas, Offset(cx - 48, cy - 38), AppColors.primary, 1.2);
    _drawPin(canvas, Offset(cx + 58, cy - 18 + 5 * math.sin(t * math.pi * 2)),
        AppColors.accent, 1.0);
    _drawPin(canvas, Offset(cx - 18, cy + 28), AppColors.riskMedium, 0.9);

    // Carte médecin
    final cardY = cy + 64 + 5 * math.sin(t * math.pi * 2 + 1);
    _drawDoctorCard(canvas, Offset(cx, cardY), size.width * 0.72);
  }

  void _drawPin(Canvas canvas, Offset pos, Color color, double scale) {
    // Ombre
    canvas.drawCircle(pos.translate(0, 4), 11 * scale,
        Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    // Cercle
    canvas.drawCircle(pos, 12 * scale, Paint()..color = color);
    canvas.drawCircle(pos, 5 * scale, Paint()..color = Colors.white);
    // Queue
    final tail = Path()
      ..moveTo(pos.dx - 6 * scale, pos.dy + 8 * scale)
      ..lineTo(pos.dx + 6 * scale, pos.dy + 8 * scale)
      ..lineTo(pos.dx, pos.dy + 18 * scale)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
  }

  void _drawDoctorCard(Canvas canvas, Offset center, double cardW) {
    const cardH = 60.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: cardW, height: cardH),
          const Radius.circular(16)),
      Paint()
        ..color = AppColors.primary.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: cardW, height: cardH),
          const Radius.circular(16)),
      Paint()..color = AppColors.bgWhite,
    );

    // Avatar
    final ax = center.dx - cardW / 2 + 34;
    canvas.drawCircle(Offset(ax, center.dy), 18,
        Paint()..color = AppColors.primaryLight.withOpacity(0.18));
    canvas.drawCircle(Offset(ax, center.dy), 18,
        Paint()
          ..color = AppColors.primaryLight.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    // Croix médicale
    final cp = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(ax - 7, center.dy), Offset(ax + 7, center.dy), cp);
    canvas.drawLine(Offset(ax, center.dy - 7), Offset(ax, center.dy + 7), cp);

    // Texte
    final tx = center.dx - cardW / 2 + 62;
    _text(canvas, Offset(tx, center.dy - 9), 'Dr. Sarah Martin',
        12.5, AppColors.textPrimary, FontWeight.w700, false);
    _text(canvas, Offset(tx, center.dy + 9), 'Dermatologue · 0.8 km',
        11, AppColors.textSecondary, FontWeight.w400, false);

    // Étoiles
    for (int i = 0; i < 5; i++) {
      _drawStar(canvas, Offset(tx + i * 13.0, center.dy + 22), 5,
          i < 4 ? const Color(0xFFFFBD00) : AppColors.border);
    }
  }

  void _text(Canvas canvas, Offset pos, String txt, double fs,
      Color color, FontWeight fw, bool centered) {
    final tp = TextPainter(
      text: TextSpan(
          text: txt,
          style: TextStyle(
              fontSize: fs, fontWeight: fw,
              color: color, fontFamily: 'Nunito')),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = centered ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy - tp.height / 2));
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 4 * math.pi / 5;
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.t != t;
}