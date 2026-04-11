import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'tracking_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<TrackingProvider>().syncFromBackend(auth.accessToken);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrackingProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, prov)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTimeline(prov),
                  const SizedBox(height: 16),
                  _buildCurrentEntry(prov),
                  const SizedBox(height: 16),
                  _buildEvolutionGraph(prov),
                  const SizedBox(height: 16),
                  _buildSymptoms(prov),
                  const SizedBox(height: 16),
                  _buildAddButton(context),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, TrackingProvider prov) {
    final color = prov.riskColor(prov.safeCurrent.risk);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go('/bodymap'),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Suivi — ${prov.lesionId}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text(prov.lesionZone,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            prov.riskLabel(prov.safeCurrent.risk),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Timeline ──────────────────────────────────────────────
  Widget _buildTimeline(TrackingProvider prov) {
    if (prov.entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Aucun historique disponible.'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
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
          const Text('Historique des scans',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          Row(
            children: prov.entries.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              final isSelected = i == prov.selectedEntry;
              final color = prov.riskColor(e.risk);
              final isLast = i == prov.entries.length - 1;

              return Expanded(
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => prov.selectEntry(i),
                      child: Column(children: [
                        // Dot
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 22 : 16,
                          height: isSelected ? 22 : 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: isSelected
                                ? Border.all(
                                    color: color.withOpacity(0.3), width: 4)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 8)
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          prov.formatDate(e.date).split(' ').take(2).join(' '),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected ? color : AppColors.textHint,
                          ),
                        ),
                        Text(
                          prov.formatDate(e.date).split(' ').last,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 8,
                            color: isSelected
                                ? color.withOpacity(0.7)
                                : AppColors.textHint.withOpacity(0.6),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  // Ligne de connexion
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 28),
                        color: AppColors.border,
                      ),
                    ),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Entrée sélectionnée ───────────────────────────────────
  Widget _buildCurrentEntry(TrackingProvider prov) {
    final e = prov.safeCurrent;
    final color = prov.riskColor(e.risk);

    // Couleur et pourcentage du scan précédent
    final Color prevColor = prov.selectedEntry > 0
        ? prov.riskColor(prov.entries[prov.selectedEntry - 1].risk)
        : AppColors.border;
    final double prevPercent = prov.selectedEntry > 0
        ? prov.entries[prov.selectedEntry - 1].riskPercent
        : 0.0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(prov.selectedEntry),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + risque
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(prov.formatDate(e.date),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(e.riskPercent * 100).toInt()}% — ${prov.riskLabel(e.risk)}',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Comparaison avant/après
            Row(children: [
              Expanded(
                child: _ScanPreview(
                  label: 'Scan précédent',
                  color: prevColor,
                  percent: prevPercent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScanPreview(
                  label: 'Scan actuel',
                  color: color,
                  percent: e.riskPercent,
                  isCurrent: true,
                ),
              ),
            ]),
            const SizedBox(height: 14),

            // Notes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_rounded,
                      color: AppColors.textHint, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.notes,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Graphique d'évolution ─────────────────────────────────
  Widget _buildEvolutionGraph(TrackingProvider prov) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
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
          const Text('Évolution du risque',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _GraphPainter(
                entries: prov.entries,
                selectedIndex: prov.selectedEntry,
                provider: prov,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Symptômes ─────────────────────────────────────────────
  Widget _buildSymptoms(TrackingProvider prov) {
    final symptoms = prov.safeCurrent.symptoms;

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
          const Row(children: [
            Icon(Icons.medical_information_rounded,
                color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text('Symptômes signalés',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((s) {
              final isOk = s == 'Aucun symptôme';
              final color = isOk ? AppColors.riskLow : AppColors.riskMedium;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isOk ? Icons.check_circle_rounded : Icons.circle_rounded,
                    color: color,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(s,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      )),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Bouton ajouter ────────────────────────────────────────
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/camera'),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Ajouter un nouveau scan', style: AppFonts.labelBtn),
          ],
        ),
      ),
    );
  }
}

// ── Aperçu scan ───────────────────────────────────────────────
class _ScanPreview extends StatelessWidget {
  final String label;
  final Color color;
  final double percent;
  final bool isCurrent;

  const _ScanPreview({
    required this.label,
    required this.color,
    required this.percent,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent ? color.withOpacity(0.07) : AppColors.bgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? color.withOpacity(0.25) : AppColors.border,
        ),
      ),
      child: Column(children: [
        // Simulation visuelle de la lésion
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: CustomPaint(
            painter: _LesionPreviewPainter(color: color, percent: percent),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              color: AppColors.textHint,
            )),
        Text(
          percent > 0 ? '${(percent * 100).toInt()}%' : '—',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ]),
    );
  }
}

// ── Painter lésion preview ────────────────────────────────────
class _LesionPreviewPainter extends CustomPainter {
  final Color color;
  final double percent;
  _LesionPreviewPainter({required this.color, required this.percent});

  @override
  void paint(Canvas canvas, Size size) {
    if (percent == 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width / 2 - 8) * percent.clamp(0.2, 1.0);

    canvas.drawCircle(c, r, Paint()..color = color.withOpacity(0.6));

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(c.dx - r * 0.7, c.dy - r * 0.3 + i * r * 0.4),
        Offset(c.dx + r * 0.7, c.dy - r * 0.3 + i * r * 0.4),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Graphique d'évolution ─────────────────────────────────────
class _GraphPainter extends CustomPainter {
  final List<TrackingEntry> entries;
  final int selectedIndex;
  final TrackingProvider provider;

  _GraphPainter({
    required this.entries,
    required this.selectedIndex,
    required this.provider,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    if (entries.length == 1) {
      final entry = entries.first;
      final point = Offset(
        size.width / 2,
        size.height - entry.riskPercent * size.height * 0.85,
      );
      final color = provider.riskColor(entry.risk);

      canvas.drawCircle(point, 7, Paint()..color = color);
      canvas.drawCircle(
        point,
        11,
        Paint()
          ..color = color.withOpacity(0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }

    final w = size.width;
    final h = size.height;
    final stepX = w / (entries.length - 1);

    final points = entries.asMap().entries.map((e) {
      return Offset(e.key * stepX, h - e.value.riskPercent * h * 0.85);
    }).toList();

    // Zone remplie sous la courbe
    final areaPath = Path()..moveTo(points.first.dx, h);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, h);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.18),
            AppColors.primary.withOpacity(0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Ligne de courbe
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Points sur la courbe
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final color = provider.riskColor(entries[i].risk);
      final isSelected = i == selectedIndex;

      canvas.drawCircle(p, isSelected ? 7 : 5, Paint()..color = color);
      if (isSelected) {
        canvas.drawCircle(
          p,
          11,
          Paint()
            ..color = color.withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // Ligne verticale sélectionnée
    final selPt = points[selectedIndex];
    canvas.drawLine(
      Offset(selPt.dx, 0),
      Offset(selPt.dx, h),
      Paint()
        ..color = AppColors.primary.withOpacity(0.2)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.selectedIndex != selectedIndex;
}
