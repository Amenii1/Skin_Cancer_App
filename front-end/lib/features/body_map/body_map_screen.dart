import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'body_map_provider.dart';

class BodyMapScreen extends StatefulWidget {
  const BodyMapScreen({super.key});

  @override
  State<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends State<BodyMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BodyMapProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, prov)),
            SliverToBoxAdapter(child: _buildStats(prov)),
            SliverToBoxAdapter(child: _buildBodySection(context, prov)),
            SliverToBoxAdapter(child: _buildZoneDetail(context, prov)),
            SliverToBoxAdapter(child: _buildZoneList(prov)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, BodyMapProvider prov) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: AppColors.bgWhite,
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go('/dashboard'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Carte corporelle',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text('Sélectionnez une zone pour les détails',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        // Toggle avant/arrière
        GestureDetector(
          onTap: prov.toggleView,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(
                prov.showFront
                    ? Icons.man_rounded
                    : Icons.accessibility_new_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                prov.showFront ? 'Face' : 'Dos',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Stats globales ────────────────────────────────────────
  Widget _buildStats(BodyMapProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        _StatChip(
          value: '${prov.totalLesions}',
          label: 'Lésions totales',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatChip(
          value: '${prov.highRiskCount}',
          label: 'Zones à risque élevé',
          color: AppColors.riskHigh,
        ),
        const SizedBox(width: 10),
        _StatChip(
          value: prov.showFront ? 'Face' : 'Dos',
          label: 'Vue active',
          color: AppColors.accent,
        ),
      ]),
    );
  }

  // ── Section corps ─────────────────────────────────────────
  Widget _buildBodySection(BuildContext context, BodyMapProvider prov) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(children: [
          // Légende
          _buildLegend(),
          const SizedBox(height: 20),
          // Silhouette interactive
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: GestureDetector(
                  key: ValueKey(prov.showFront),
                  onTapDown: (details) =>
                      _handleTap(details.localPosition, prov, context),
                  child: SizedBox(
                    width: 200,
                    height: 340,
                    child: CustomPaint(
                      painter: _FullBodyPainter(
                        provider: prov,
                        isFront: prov.showFront,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(children: [
              Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text('Appuyez sur une zone pour voir les détails',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ]),
          ),
        ]),
      ),
    );
  }

  void _handleTap(Offset pos, BodyMapProvider prov, BuildContext context) {
    // Coordonnées relatives à la silhouette 200×340
    final zones = _getZoneHitboxes(prov.showFront);
    for (final entry in zones.entries) {
      if (entry.value.contains(pos)) {
        prov.selectZone(entry.key);
        return;
      }
    }
  }

  Map<String, Rect> _getZoneHitboxes(bool front) {
    if (front) {
      return {
        'head': const Rect.fromLTWH(70, 0, 60, 55),
        'neck': const Rect.fromLTWH(80, 55, 40, 20),
        'chest': const Rect.fromLTWH(55, 75, 90, 70),
        'leftArm': const Rect.fromLTWH(10, 75, 45, 110),
        'rightArm': const Rect.fromLTWH(145, 75, 45, 110),
        'abdomen': const Rect.fromLTWH(60, 145, 80, 60),
        'leftLeg': const Rect.fromLTWH(55, 205, 45, 130),
        'rightLeg': const Rect.fromLTWH(100, 205, 45, 130),
      };
    } else {
      return {
        'backHead': const Rect.fromLTWH(70, 0, 60, 55),
        'upperBack': const Rect.fromLTWH(55, 75, 90, 60),
        'lowerBack': const Rect.fromLTWH(60, 135, 80, 60),
        'leftBackArm': const Rect.fromLTWH(10, 75, 45, 110),
        'rightBackArm': const Rect.fromLTWH(145, 75, 45, 110),
        'buttocks': const Rect.fromLTWH(60, 195, 80, 50),
        'leftBackLeg': const Rect.fromLTWH(55, 245, 45, 90),
        'rightBackLeg': const Rect.fromLTWH(100, 245, 45, 90),
      };
    }
  }

  // ── Détail zone sélectionnée ──────────────────────────────
  Widget _buildZoneDetail(BuildContext context, BodyMapProvider prov) {
    final zone = prov.selectedZone;
    if (zone == null) return const SizedBox.shrink();

    final color = prov.zoneColor(zone.risk);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${zone.lesionCount}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                Text(prov.riskLabel(zone.risk),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    )),
                Text(
                  '${zone.lesionCount} lésion(s) enregistrée(s)',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/tracking'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Voir',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Liste des zones ───────────────────────────────────────
  Widget _buildZoneList(BodyMapProvider prov) {
    final zones = prov.activeZones.where((z) => z.lesionCount > 0).toList();

    if (zones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Zones avec lésions',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 12),
          ...zones.map((z) {
            final color = prov.zoneColor(z.risk);
            final isSelected = prov.selectedZoneId == z.id;
            return GestureDetector(
              onTap: () => prov.selectZone(z.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.07)
                      : AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.3)
                        : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(z.label,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        )),
                  ),
                  Text('${z.lesionCount} lésion(s)',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.textHint,
                      )),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(prov.riskLabel(z.risk),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        )),
                  ),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Légende ───────────────────────────────────────────────
  Widget _buildLegend() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.border, label: 'Aucune'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.riskLow, label: 'Faible'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.riskMedium, label: 'Modéré'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.riskHigh, label: 'Élevé'),
        SizedBox(width: 14),
        _LegendDot(color: AppColors.primary, label: 'Sélectionné'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            color: AppColors.textHint,
          )),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatChip(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.3,
              )),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CustomPaint — Silhouette complète interactive
// ══════════════════════════════════════════════════════════════
class _FullBodyPainter extends CustomPainter {
  final BodyMapProvider provider;
  final bool isFront;
  _FullBodyPainter({required this.provider, required this.isFront});

  Color _c(String id) {
    final zones = isFront ? provider.frontZones : provider.backZones;
    try {
      final z = zones.firstWhere((z) => z.id == id);
      final selected = provider.selectedZoneId == id;
      return provider.zoneColor(z.risk, selected: selected);
    } catch (_) {
      return AppColors.border;
    }
  }

  void _drawZone(Canvas canvas, Path path, String id) {
    final color = _c(id);
    final isSelected = provider.selectedZoneId == id;

    // Remplissage
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.75));

    // Bordure
    canvas.drawPath(
      path,
      Paint()
        ..color = isSelected ? AppColors.primary : Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.0,
    );

    // Halo si sélectionné
    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    if (isFront) {
      _paintFront(canvas, size, cx);
    } else {
      _paintBack(canvas, size, cx);
    }
  }

  void _paintFront(Canvas canvas, Size size, double cx) {
    // ── Tête ──────────────────────────────────────────────
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, 28), width: 52, height: 54));
    _drawZone(canvas, headPath, 'head');

    // ── Cou ───────────────────────────────────────────────
    final neckPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 63), width: 20, height: 18),
          const Radius.circular(4)));
    _drawZone(canvas, neckPath, 'neck');

    // ── Torse ─────────────────────────────────────────────
    final chestPath = Path()
      ..moveTo(cx - 44, 72)
      ..lineTo(cx + 44, 72)
      ..lineTo(cx + 38, 148)
      ..lineTo(cx - 38, 148)
      ..close();
    _drawZone(canvas, chestPath, 'chest');

    // ── Bras gauche ───────────────────────────────────────
    final leftArmPath = Path()
      ..moveTo(cx - 44, 74)
      ..lineTo(cx - 60, 80)
      ..lineTo(cx - 58, 150)
      ..lineTo(cx - 48, 150)
      ..lineTo(cx - 44, 130)
      ..close();
    _drawZone(canvas, leftArmPath, 'leftArm');

    // Avant-bras gauche
    final leftForearmPath = Path()
      ..moveTo(cx - 60, 150)
      ..lineTo(cx - 64, 155)
      ..lineTo(cx - 60, 210)
      ..lineTo(cx - 50, 208)
      ..lineTo(cx - 48, 150)
      ..close();
    _drawZone(canvas, leftForearmPath, 'leftArm');

    // ── Bras droit ────────────────────────────────────────
    final rightArmPath = Path()
      ..moveTo(cx + 44, 74)
      ..lineTo(cx + 60, 80)
      ..lineTo(cx + 58, 150)
      ..lineTo(cx + 48, 150)
      ..lineTo(cx + 44, 130)
      ..close();
    _drawZone(canvas, rightArmPath, 'rightArm');

    // Avant-bras droit
    final rightForearmPath = Path()
      ..moveTo(cx + 60, 150)
      ..lineTo(cx + 64, 155)
      ..lineTo(cx + 60, 210)
      ..lineTo(cx + 50, 208)
      ..lineTo(cx + 48, 150)
      ..close();
    _drawZone(canvas, rightForearmPath, 'rightArm');

    // ── Abdomen ───────────────────────────────────────────
    final abdoPath = Path()
      ..moveTo(cx - 38, 148)
      ..lineTo(cx + 38, 148)
      ..lineTo(cx + 34, 205)
      ..lineTo(cx - 34, 205)
      ..close();
    _drawZone(canvas, abdoPath, 'abdomen');

    // ── Jambe gauche ──────────────────────────────────────
    final leftLegPath = Path()
      ..moveTo(cx - 34, 205)
      ..lineTo(cx - 4, 205)
      ..lineTo(cx - 8, 300)
      ..lineTo(cx - 36, 298)
      ..close();
    _drawZone(canvas, leftLegPath, 'leftLeg');

    // ── Jambe droite ──────────────────────────────────────
    final rightLegPath = Path()
      ..moveTo(cx + 34, 205)
      ..lineTo(cx + 4, 205)
      ..lineTo(cx + 8, 300)
      ..lineTo(cx + 36, 298)
      ..close();
    _drawZone(canvas, rightLegPath, 'rightLeg');

    // ── Pieds ─────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 38, 298, 30, 12), const Radius.circular(4)),
      Paint()..color = AppColors.border.withOpacity(0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 8, 298, 30, 12), const Radius.circular(4)),
      Paint()..color = AppColors.border.withOpacity(0.8),
    );

    // ── Indicateurs de lésion ─────────────────────────────
    _drawLesionIndicators(canvas, isFront: true, cx: cx);
  }

  void _paintBack(Canvas canvas, Size size, double cx) {
    // ── Nuque ─────────────────────────────────────────────
    final headPath = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx, 28), width: 52, height: 54));
    _drawZone(canvas, headPath, 'backHead');

    // ── Haut du dos ───────────────────────────────────────
    final upperBackPath = Path()
      ..moveTo(cx - 44, 72)
      ..lineTo(cx + 44, 72)
      ..lineTo(cx + 40, 140)
      ..lineTo(cx - 40, 140)
      ..close();
    _drawZone(canvas, upperBackPath, 'upperBack');

    // ── Bras gauche dos ───────────────────────────────────
    final leftArmPath = Path()
      ..moveTo(cx - 44, 74)
      ..lineTo(cx - 60, 80)
      ..lineTo(cx - 58, 150)
      ..lineTo(cx - 48, 150)
      ..lineTo(cx - 44, 130)
      ..close();
    _drawZone(canvas, leftArmPath, 'leftBackArm');

    final leftForearmPath = Path()
      ..moveTo(cx - 60, 150)
      ..lineTo(cx - 64, 155)
      ..lineTo(cx - 60, 210)
      ..lineTo(cx - 50, 208)
      ..lineTo(cx - 48, 150)
      ..close();
    _drawZone(canvas, leftForearmPath, 'leftBackArm');

    // ── Bras droit dos ────────────────────────────────────
    final rightArmPath = Path()
      ..moveTo(cx + 44, 74)
      ..lineTo(cx + 60, 80)
      ..lineTo(cx + 58, 150)
      ..lineTo(cx + 48, 150)
      ..lineTo(cx + 44, 130)
      ..close();
    _drawZone(canvas, rightArmPath, 'rightBackArm');

    final rightForearmPath = Path()
      ..moveTo(cx + 60, 150)
      ..lineTo(cx + 64, 155)
      ..lineTo(cx + 60, 210)
      ..lineTo(cx + 50, 208)
      ..lineTo(cx + 48, 150)
      ..close();
    _drawZone(canvas, rightForearmPath, 'rightBackArm');

    // ── Bas du dos ────────────────────────────────────────
    final lowerBackPath = Path()
      ..moveTo(cx - 40, 140)
      ..lineTo(cx + 40, 140)
      ..lineTo(cx + 36, 200)
      ..lineTo(cx - 36, 200)
      ..close();
    _drawZone(canvas, lowerBackPath, 'lowerBack');

    // ── Fessiers ──────────────────────────────────────────
    final buttPath = Path()
      ..moveTo(cx - 36, 200)
      ..lineTo(cx + 36, 200)
      ..lineTo(cx + 34, 250)
      ..lineTo(cx - 34, 250)
      ..close();
    _drawZone(canvas, buttPath, 'buttocks');

    // ── Jambes dos ────────────────────────────────────────
    final leftLegPath = Path()
      ..moveTo(cx - 34, 250)
      ..lineTo(cx - 4, 250)
      ..lineTo(cx - 8, 330)
      ..lineTo(cx - 36, 328)
      ..close();
    _drawZone(canvas, leftLegPath, 'leftBackLeg');

    final rightLegPath = Path()
      ..moveTo(cx + 34, 250)
      ..lineTo(cx + 4, 250)
      ..lineTo(cx + 8, 330)
      ..lineTo(cx + 36, 328)
      ..close();
    _drawZone(canvas, rightLegPath, 'rightBackLeg');

    // Pieds
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 38, 328, 30, 12), const Radius.circular(4)),
      Paint()..color = AppColors.border.withOpacity(0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 8, 328, 30, 12), const Radius.circular(4)),
      Paint()..color = AppColors.border.withOpacity(0.8),
    );

    _drawLesionIndicators(canvas, isFront: false, cx: cx);
  }

  void _drawLesionIndicators(Canvas canvas,
      {required bool isFront, required double cx}) {
    final zones = isFront ? provider.frontZones : provider.backZones;

    final Map<String, Offset> positions = isFront
        ? {
            'head': Offset(cx, 28),
            'chest': Offset(cx, 108),
            'leftArm': Offset(cx - 55, 115),
            'rightArm': Offset(cx + 55, 115),
            'abdomen': Offset(cx, 175),
            'leftLeg': Offset(cx - 22, 250),
            'rightLeg': Offset(cx + 22, 250),
          }
        : {
            'backHead': Offset(cx, 28),
            'upperBack': Offset(cx, 106),
            'lowerBack': Offset(cx, 170),
            'leftBackArm': Offset(cx - 55, 115),
            'rightBackArm': Offset(cx + 55, 115),
            'buttocks': Offset(cx, 225),
            'leftBackLeg': Offset(cx - 22, 290),
            'rightBackLeg': Offset(cx + 22, 290),
          };

    for (final z in zones) {
      if (z.lesionCount == 0) continue;
      final pos = positions[z.id];
      if (pos == null) continue;

      final color = provider.zoneColor(z.risk);

      // Halo
      canvas.drawCircle(pos, 11, Paint()..color = color.withOpacity(0.25));
      // Cercle
      canvas.drawCircle(pos, 8, Paint()..color = color);
      // Nombre
      final tp = TextPainter(
        text: TextSpan(
          text: '${z.lesionCount}',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _FullBodyPainter old) =>
      old.provider.selectedZoneId != provider.selectedZoneId ||
      old.isFront != isFront;
}
