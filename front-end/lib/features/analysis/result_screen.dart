import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'result_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late AnimationController _gaugeCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _gaugeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
        parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryCtrl, curve: Curves.easeOutCubic));

    _gaugeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gaugeAnim = CurvedAnimation(
        parent: _gaugeCtrl, curve: Curves.easeOutCubic);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _gaugeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _gaugeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ResultProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, prov)),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildGaugeCard(prov),
                    const SizedBox(height: 16),
                    _buildConfidenceCard(prov),
                    const SizedBox(height: 16),
                    _buildABCDECard(prov),
                    const SizedBox(height: 16),
                    _buildDescriptionCard(prov),
                    const SizedBox(height: 16),
                    _buildRecommendations(prov),
                    const SizedBox(height: 16),
                    _buildActionButtons(context, prov),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ResultProvider prov) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            prov.riskColor.withOpacity(0.15),
            AppColors.bgWhite,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              onTap: () => context.go('/camera'),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary, size: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résultat d\'analyse',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Zone : ${prov.zone} · IA DermaScan',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            // Badge risque
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: prov.riskColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: prov.riskColor.withOpacity(0.3)),
              ),
              child: Text(
                '${prov.riskEmoji} ${prov.riskLabel}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: prov.riskColor,
                ),
              ),
            ),
          ]),

          // Simulateur de risque (debug)
          const SizedBox(height: 16),
          _RiskSimulator(),
        ],
      ),
    );
  }

  // ── Gauge de risque ───────────────────────────────────────
  Widget _buildGaugeCard(ResultProvider prov) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: prov.riskColor.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        const Text(
          'Score de risque',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Gauge arc
        AnimatedBuilder(
          animation: Listenable.merge([_gaugeAnim, _pulseCtrl]),
          builder: (_, __) {
            return SizedBox(
              width: 200, height: 120,
              child: Stack(alignment: Alignment.center, children: [
                // Arc gauge
                CustomPaint(
                  size: const Size(200, 120),
                  painter: _GaugePainter(
                    value: _gaugeAnim.value * prov.riskPercent,
                    color: prov.riskColor,
                  ),
                ),
                // Valeur centrale
                Positioned(
                  bottom: 0,
                  child: Transform.scale(
                    scale: _pulseAnim.value,
                    child: Column(children: [
                      Text(
                        '${(prov.riskPercent * 100).toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: prov.riskColor,
                        ),
                      ),
                      Text(
                        'Risque ${prov.riskLabel}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }

  // ── Confiance IA ──────────────────────────────────────────
  Widget _buildConfidenceCard(ResultProvider prov) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.psychology_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confiance du modèle IA',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _gaugeAnim,
                builder: (_, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _gaugeAnim.value * prov.confidence,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          '${(prov.confidence * 100).toInt()}%',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ]),
    );
  }

  // ── Critères ABCDE ────────────────────────────────────────
  Widget _buildABCDECard(ResultProvider prov) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.biotech_rounded,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Critères ABCDE détectés',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: prov.toggleDetails,
              child: Text(
                prov.showDetails ? 'Réduire' : 'Détails',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: prov.detectedFeatures.map((f) {
              final ok = f['ok'] as bool;
              final color = ok ? AppColors.riskLow : AppColors.riskHigh;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    ok ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: color,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (prov.showDetails) ...[
                    const SizedBox(width: 4),
                    Text(
                      '· ${f['value']}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Description ───────────────────────────────────────────
  Widget _buildDescriptionCard(ResultProvider prov) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: prov.riskColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: prov.riskColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prov.riskEmoji,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prov.riskDescription,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recommandations ───────────────────────────────────────
  Widget _buildRecommendations(ResultProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommandations',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...prov.recommendations.map((rec) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: rec.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(rec.icon, color: rec.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    rec.description,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint, size: 14),
          ]),
        )),
      ],
    );
  }

  // ── Boutons d'action ──────────────────────────────────────
  Widget _buildActionButtons(BuildContext context, ResultProvider prov) {
    return Column(children: [
      // Bouton principal
      GestureDetector(
        onTap: () => context.go('/dashboard'),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [prov.riskColor, prov.riskColor.withOpacity(0.7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: prov.riskColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              prov.risk == ResultRisk.high
                  ? 'Trouver un dermatologue'
                  : 'Démarrer le suivi',
              style: AppFonts.labelBtn,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Bouton secondaire
      GestureDetector(
        onTap: () => context.go('/dashboard'),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text(
              'Retour au tableau de bord',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Gauge arc ─────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 10;
    final r = size.width / 2 - 16;

    final bgPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Arc background
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Arc valeur
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      math.pi,
      math.pi * value,
      false,
      fgPaint,
    );

    // Labels min/max
    _drawText(canvas, '0%', Offset(16, cy + 8), 11, AppColors.textHint);
    _drawText(canvas, '100%', Offset(size.width - 36, cy + 8), 11, AppColors.textHint);
  }

  void _drawText(Canvas canvas, String text, Offset pos,
      double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

// ── Simulateur de risque (debug/demo) ────────────────────────
class _RiskSimulator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.read<ResultProvider>();

    return Row(children: [
      const Text(
        'Simuler :',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          color: AppColors.textHint,
        ),
      ),
      const SizedBox(width: 10),
      _SimBtn(
          label: 'Faible',
          color: AppColors.riskLow,
          onTap: () => prov.simulateResult(ResultRisk.low)),
      const SizedBox(width: 6),
      _SimBtn(
          label: 'Modéré',
          color: AppColors.riskMedium,
          onTap: () => prov.simulateResult(ResultRisk.medium)),
      const SizedBox(width: 6),
      _SimBtn(
          label: 'Élevé',
          color: AppColors.riskHigh,
          onTap: () => prov.simulateResult(ResultRisk.high)),
    ]);
  }
}

class _SimBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SimBtn(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}