import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../dashboard_provider.dart';

class RiskSummaryCard extends StatelessWidget {
  const RiskSummaryCard({super.key});

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
                'Résumé de risque',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: prov.globalRiskColor(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: prov.globalRiskColor(context),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Risque ${prov.globalRiskLabel}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: prov.globalRiskColor(context),
                    ),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stats row
          Row(children: [
            _StatBox(
              value: '${prov.totalLesions}',
              label: 'Lésions\nsuivies',
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            _StatBox(
              value: '${prov.daysSinceLastScan}j',
              label: 'Depuis\ndernier scan',
              color: AppColors.riskMedium,
            ),
            const SizedBox(width: 12),
            _StatBox(
              value: '1',
              label: 'Alerte\nactive',
              color: AppColors.riskHigh,
            ),
          ]),
          const SizedBox(height: 18),

          // Lésions récentes
          const Text(
            'Dernières lésions',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ...prov.recentLesions.map((l) => _LesionRow(lesion: l)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ]),
      ),
    );
  }
}

class _LesionRow extends StatelessWidget {
  final LesionRecord lesion;
  const _LesionRow({required this.lesion});

  @override
  Widget build(BuildContext context) {
    final color = DashboardProvider.riskColor(lesion.risk);
    final label = DashboardProvider.riskLabel(lesion.risk);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        // Avatar lésion
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              lesion.imageLabel,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesion.zone,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatDate(lesion.date),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        // Badge risque
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
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
      ]),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d).inDays;
    if (diff == 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return 'Il y a $diff jours';
  }
}