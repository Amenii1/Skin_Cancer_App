import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum RiskLevel { low, medium, high }

class LesionRecord {
  final String id;
  final String zone;
  final RiskLevel risk;
  final DateTime date;
  final String imageLabel;

  const LesionRecord({
    required this.id,
    required this.zone,
    required this.risk,
    required this.date,
    required this.imageLabel,
  });
}

class ReminderItem {
  final String title;
  final String subtitle;
  final String date;
  final RiskLevel urgency;
  bool isDone;

  ReminderItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.urgency,
    this.isDone = false,
  });
}

class DashboardProvider extends ChangeNotifier {
  String userName = 'Utilisateur';
  int totalLesions = 0;
  RiskLevel globalRisk = RiskLevel.low;
  int daysSinceLastScan = 0;

  final List<LesionRecord> recentLesions = [];
  final List<ReminderItem> reminders = [];
  String? _accessToken;
  bool _loading = false;
  String? _error;

  // Zones du body map avec niveau de risque
  // clé = zone, valeur = risque
  final Map<String, RiskLevel> bodyZones = <String, RiskLevel>{
    'head': RiskLevel.low,
    'chest': RiskLevel.low,
    'leftArm': RiskLevel.low,
    'rightArm': RiskLevel.low,
    'abdomen': RiskLevel.low,
    'back': RiskLevel.low,
    'leftLeg': RiskLevel.low,
    'rightLeg': RiskLevel.low,
  };

  bool get loading => _loading;
  String? get error => _error;

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final api = ApiClient(accessToken: _accessToken);
      final stats = await api.getJson('/stats/dashboard');
      final role = stats['role']?.toString() ?? '';

      if (role == 'doctor') {
        final nom = stats['nom']?.toString().trim();
        if (nom != null && nom.isNotEmpty) {
          userName = nom.split(' ').first;
        } else {
          userName = 'Médecin';
        }
        totalLesions = 0;
        daysSinceLastScan = 0;
        globalRisk = RiskLevel.low;
        recentLesions.clear();
        reminders.clear();
        return;
      }

      if (role != 'patient') {
        _error = 'Profil non pris en charge pour le tableau de bord.';
        return;
      }

      final name = stats['nom']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        userName = name.split(' ').first;
      }

      totalLesions = (stats['total_lesions'] as num?)?.toInt() ?? 0;
      final days = stats['days_since_last_scan'];
      if (days is num) {
        daysSinceLastScan = days.toInt();
      } else {
        daysSinceLastScan = 0;
      }

      globalRisk = _riskFromGlobalString(
        stats['global_risk']?.toString() ?? 'low',
      );

      final recent = (stats['recent_images'] as List?) ?? const [];
      recentLesions
        ..clear()
        ..addAll(
          recent.map((raw) {
            final m = (raw as Map).cast<String, dynamic>();
            final id = m['id']?.toString() ?? '';
            final date = DateTime.tryParse(
                  m['observation_date']?.toString() ?? '',
                ) ??
                DateTime.now();
            final result = m['result']?.toString() ?? '';
            final risk = _riskFromResult(result);
            return LesionRecord(
              id: id,
              zone: 'Lésion $id',
              risk: risk,
              date: date,
              imageLabel: 'L$id',
            );
          }),
        );

      final notifs = (stats['notifications_preview'] as List?) ?? const [];
      reminders
        ..clear()
        ..addAll(
          notifs.take(3).map((raw) {
            final n = (raw as Map).cast<String, dynamic>();
            final title = n['title']?.toString() ?? 'Notification';
            final body = n['body']?.toString() ?? '';
            final createdAt =
                DateTime.tryParse(n['created_at']?.toString() ?? '');
            return ReminderItem(
              title: title,
              subtitle: body,
              date: _formatRelative(createdAt),
              urgency: _urgencyFromKind(n['kind']?.toString() ?? ''),
              isDone: n['read'] == true,
            );
          }),
        );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Erreur de chargement du tableau de bord.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void toggleReminder(int index) {
    reminders[index].isDone = !reminders[index].isDone;
    notifyListeners();
  }

  String get globalRiskLabel {
    switch (globalRisk) {
      case RiskLevel.low:
        return 'Faible';
      case RiskLevel.medium:
        return 'Modéré';
      case RiskLevel.high:
        return 'Élevé';
    }
  }

  Color globalRiskColor(BuildContext context) {
    switch (globalRisk) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.high:
        return AppColors.riskHigh;
    }
  }

  static Color riskColor(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return AppColors.riskLow;
      case RiskLevel.medium:
        return AppColors.riskMedium;
      case RiskLevel.high:
        return AppColors.riskHigh;
    }
  }

  static String riskLabel(RiskLevel r) {
    switch (r) {
      case RiskLevel.low:
        return 'Faible';
      case RiskLevel.medium:
        return 'Modéré';
      case RiskLevel.high:
        return 'Élevé';
    }
  }

  RiskLevel _riskFromResult(String result) {
    switch (result) {
      case 'melanoma':
        return RiskLevel.high;
      case 'basal_cell_carcinoma':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  RiskLevel _riskFromGlobalString(String s) {
    switch (s) {
      case 'high':
        return RiskLevel.high;
      case 'medium':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }

  RiskLevel _urgencyFromKind(String kind) {
    if (kind.contains('high')) return RiskLevel.high;
    if (kind.contains('warning')) return RiskLevel.medium;
    return RiskLevel.low;
  }

  String _formatRelative(DateTime? d) {
    if (d == null) return '—';
    final diff = DateTime.now().difference(d).inDays;
    if (diff <= 0) return 'Aujourd\'hui';
    if (diff == 1) return 'Hier';
    return 'Il y a $diff jours';
  }
}
