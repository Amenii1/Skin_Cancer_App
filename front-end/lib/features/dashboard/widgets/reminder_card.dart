import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../dashboard_provider.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key});

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
                'Rappels & Suivi',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${prov.reminders.where((r) => !r.isDone).length} actifs',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Liste des rappels
          ...prov.reminders.asMap().entries.map(
            (entry) => _ReminderTile(
              item: entry.value,
              index: entry.key,
              onToggle: () => prov.toggleReminder(entry.key),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderItem item;
  final int index;
  final VoidCallback onToggle;

  const _ReminderTile({
    required this.item,
    required this.index,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = DashboardProvider.riskColor(item.urgency);

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isDone
              ? AppColors.bgSoft
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isDone
                ? AppColors.border
                : color.withOpacity(0.2),
          ),
        ),
        child: Row(children: [
          // Indicateur urgence
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: item.isDone ? AppColors.border : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.isDone
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                    decoration: item.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: item.isDone
                        ? AppColors.textHint
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Date + checkbox
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.date,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: item.isDone ? AppColors.textHint : color,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: item.isDone ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isDone ? color : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: item.isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ]),
      ),
    );
  }
}