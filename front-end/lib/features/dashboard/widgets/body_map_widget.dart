import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../dashboard_provider.dart';

class BodyMapWidget extends StatelessWidget {
  const BodyMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DashboardProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Carte corporelle',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Body map + légende
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Silhouette
              SizedBox(
                width: 120,
                height: 200,
                child: CustomPaint(
                  painter: _BodyPainter(zones: prov.bodyZones),
                ),
              ),
              const SizedBox(width: 20),
              // Légende + détails
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _Legend(),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.border, thickness: 1),
                    const SizedBox(height: 12),
                    // Zones à risque
                    _ZonesList(zones: prov.bodyZones),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Légende ───────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Niveaux de risque',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        _LegendItem(color: AppColors.riskLow, label: 'Faible'),
        const SizedBox(height: 5),
        _LegendItem(color: AppColors.riskMedium, label: 'Modéré'),
        const SizedBox(height: 5),
        _LegendItem(color: AppColors.riskHigh, label: 'Élevé'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    ]);
  }
}

// ── Zones à risque ────────────────────────────────────────────
class _ZonesList extends StatelessWidget {
  final Map<String, RiskLevel> zones;
  const _ZonesList({required this.zones});

  static const _labels = {
    'head': 'Tête',
    'chest': 'Torse',
    'leftArm': 'Bras gauche',
    'rightArm': 'Bras droit',
    'abdomen': 'Abdomen',
    'back': 'Dos',
    'leftLeg': 'Jambe gauche',
    'rightLeg': 'Jambe droite',
  };

  @override
  Widget build(BuildContext context) {
    final risky = zones.entries
        .where((e) => e.value != RiskLevel.low)
        .toList();

    if (risky.isEmpty) {
      return const Text(
        'Aucune zone à risque',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: AppColors.riskLow,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zones à surveiller',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...risky.map((e) {
          final color = DashboardProvider.riskColor(e.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _labels[e.key] ?? e.key,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ]),
          );
        }),
      ],
    );
  }
}

// ── CustomPaint silhouette ────────────────────────────────────
class _BodyPainter extends CustomPainter {
  final Map<String, RiskLevel> zones;
  _BodyPainter({required this.zones});

  Color _zoneColor(String zone) {
    final r = zones[zone] ?? RiskLevel.low;
    return DashboardProvider.riskColor(r).withOpacity(0.75);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ── Tête ──────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 18), width: 28, height: 30),
      Paint()..color = _zoneColor('head'),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 18), width: 28, height: 30),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Cou ───────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 38), width: 12, height: 10),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.border,
    );

    // ── Torse ─────────────────────────────────────────────────
    final torsoPath = Path()
      ..moveTo(cx - 22, 43)
      ..lineTo(cx + 22, 43)
      ..lineTo(cx + 18, 95)
      ..lineTo(cx - 18, 95)
      ..close();
    canvas.drawPath(torsoPath, Paint()..color = _zoneColor('chest'));
    canvas.drawPath(
      torsoPath,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Dos (indicateur) ──────────────────────────────────────
    // On dessine un marqueur "dos" sur le côté du torse
    if ((zones['back'] ?? RiskLevel.low) != RiskLevel.low) {
      final backColor = DashboardProvider.riskColor(zones['back']!);
      canvas.drawCircle(
        Offset(cx + 26, 65),
        5,
        Paint()..color = backColor,
      );
      canvas.drawCircle(
        Offset(cx + 26, 65),
        8,
        Paint()
          ..color = backColor.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // ── Bras gauche ───────────────────────────────────────────
    final leftArmPath = Path()
      ..moveTo(cx - 22, 45)
      ..lineTo(cx - 36, 48)
      ..lineTo(cx - 34, 90)
      ..lineTo(cx - 22, 88)
      ..close();
    canvas.drawPath(leftArmPath, Paint()..color = _zoneColor('leftArm'));
    canvas.drawPath(
      leftArmPath,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Bras droit ────────────────────────────────────────────
    final rightArmPath = Path()
      ..moveTo(cx + 22, 45)
      ..lineTo(cx + 36, 48)
      ..lineTo(cx + 34, 90)
      ..lineTo(cx + 22, 88)
      ..close();
    canvas.drawPath(rightArmPath, Paint()..color = _zoneColor('rightArm'));
    canvas.drawPath(
      rightArmPath,
      Paint()
        ..color = Colors.white.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Avant-bras gauche ─────────────────────────────────────
    final leftForearmPath = Path()
      ..moveTo(cx - 34, 90)
      ..lineTo(cx - 38, 93)
      ..lineTo(cx - 36, 125)
      ..lineTo(cx - 28, 124)
      ..close();
    canvas.drawPath(leftForearmPath,
        Paint()..color = _zoneColor('leftArm').withOpacity(0.7));

    // ── Avant-bras droit ──────────────────────────────────────
    final rightForearmPath = Path()
      ..moveTo(cx + 34, 90)
      ..lineTo(cx + 38, 93)
      ..lineTo(cx + 36, 125)
      ..lineTo(cx + 28, 124)
      ..close();
    canvas.drawPath(rightForearmPath,
        Paint()..color = _zoneColor('rightArm').withOpacity(0.7));

    // ── Abdomen ───────────────────────────────────────────────
    final abdoPath = Path()
      ..moveTo(cx - 18, 95)
      ..lineTo(cx + 18, 95)
      ..lineTo(cx + 16, 125)
      ..lineTo(cx - 16, 125)
      ..close();
    canvas.drawPath(abdoPath, Paint()..color = _zoneColor('abdomen'));
    canvas.drawPath(
      abdoPath,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Jambe gauche ──────────────────────────────────────────
    final leftLegPath = Path()
      ..moveTo(cx - 16, 125)
      ..lineTo(cx - 2, 125)
      ..lineTo(cx - 4, 185)
      ..lineTo(cx - 18, 185)
      ..close();
    canvas.drawPath(leftLegPath, Paint()..color = _zoneColor('leftLeg'));
    canvas.drawPath(
      leftLegPath,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Jambe droite ──────────────────────────────────────────
    final rightLegPath = Path()
      ..moveTo(cx + 16, 125)
      ..lineTo(cx + 2, 125)
      ..lineTo(cx + 4, 185)
      ..lineTo(cx + 18, 185)
      ..close();
    canvas.drawPath(rightLegPath, Paint()..color = _zoneColor('rightLeg'));
    canvas.drawPath(
      rightLegPath,
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Pieds ─────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20, 185, 14, 8),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.border,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 6, 185, 14, 8),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.border,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.zones != zones;
}