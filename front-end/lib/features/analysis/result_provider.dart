import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ResultRisk { low, medium, high }

class Recommendation {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const Recommendation({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class ResultProvider extends ChangeNotifier {
  ResultRisk _risk = ResultRisk.medium;
  double _riskPercent = 0.62;
  double _confidence = 0.89;
  String _zone = 'Dos';
  bool _showDetails = false;

  ResultRisk get risk => _risk;
  double get riskPercent => _riskPercent;
  double get confidence => _confidence;
  String get zone => _zone;
  bool get showDetails => _showDetails;

  void toggleDetails() {
    _showDetails = !_showDetails;
    notifyListeners();
  }

  String get riskLabel {
    switch (_risk) {
      case ResultRisk.low: return 'Faible';
      case ResultRisk.medium: return 'Modéré';
      case ResultRisk.high: return 'Élevé';
    }
  }

  Color get riskColor {
    switch (_risk) {
      case ResultRisk.low: return AppColors.riskLow;
      case ResultRisk.medium: return AppColors.riskMedium;
      case ResultRisk.high: return AppColors.riskHigh;
    }
  }

  String get riskEmoji {
    switch (_risk) {
      case ResultRisk.low: return '✅';
      case ResultRisk.medium: return '⚠️';
      case ResultRisk.high: return '🚨';
    }
  }

  String get riskDescription {
    switch (_risk) {
      case ResultRisk.low:
        return 'Aucun signe préoccupant détecté. Continuez à surveiller régulièrement cette zone.';
      case ResultRisk.medium:
        return 'Des caractéristiques à surveiller ont été détectées. Un suivi régulier et une consultation médicale sont recommandés.';
      case ResultRisk.high:
        return 'Des caractéristiques importantes ont été détectées. Consultez un dermatologue dès que possible.';
    }
  }

  List<Recommendation> get recommendations {
    switch (_risk) {
      case ResultRisk.low:
        return [
          const Recommendation(
            icon: Icons.calendar_today_rounded,
            title: 'Suivi dans 3 mois',
            description: 'Rephotographiez cette lésion dans 3 mois.',
            color: AppColors.riskLow,
          ),
          const Recommendation(
            icon: Icons.wb_sunny_rounded,
            title: 'Protection solaire',
            description: 'Appliquez un SPF 50+ sur cette zone.',
            color: AppColors.riskMedium,
          ),
        ];
      case ResultRisk.medium:
        return [
          const Recommendation(
            icon: Icons.medical_services_rounded,
            title: 'Consultation recommandée',
            description: 'Consultez un dermatologue dans les 4 semaines.',
            color: AppColors.riskMedium,
          ),
          const Recommendation(
            icon: Icons.track_changes_rounded,
            title: 'Activer le suivi',
            description: 'Suivez l\'évolution de cette lésion.',
            color: AppColors.primary,
          ),
          const Recommendation(
            icon: Icons.wb_sunny_rounded,
            title: 'Éviter l\'exposition solaire',
            description: 'Protégez cette zone du soleil.',
            color: AppColors.riskMedium,
          ),
        ];
      case ResultRisk.high:
        return [
          const Recommendation(
            icon: Icons.emergency_rounded,
            title: 'Consultation urgente',
            description: 'Consultez un dermatologue dans les 48h.',
            color: AppColors.riskHigh,
          ),
          const Recommendation(
            icon: Icons.local_hospital_rounded,
            title: 'Trouver un spécialiste',
            description: 'Voir les dermatologues disponibles près de vous.',
            color: AppColors.riskHigh,
          ),
          const Recommendation(
            icon: Icons.block_rounded,
            title: 'Éviter toute exposition',
            description: 'Ne pas exposer la zone au soleil.',
            color: AppColors.riskMedium,
          ),
        ];
    }
  }

  // Caractéristiques détectées (simulations)
  List<Map<String, dynamic>> get detectedFeatures => [
    {
      'label': 'Asymétrie',
      'value': _risk == ResultRisk.low ? 'Normale' : 'Légère',
      'ok': _risk == ResultRisk.low,
    },
    {
      'label': 'Bords',
      'value': _risk == ResultRisk.high ? 'Irréguliers' : 'Réguliers',
      'ok': _risk != ResultRisk.high,
    },
    {
      'label': 'Couleur',
      'value': _risk == ResultRisk.low ? 'Uniforme' : 'Hétérogène',
      'ok': _risk == ResultRisk.low,
    },
    {
      'label': 'Diamètre',
      'value': _risk == ResultRisk.high ? '> 6mm' : '< 6mm',
      'ok': _risk != ResultRisk.high,
    },
    {
      'label': 'Évolution',
      'value': 'À confirmer',
      'ok': true,
    },
  ];

  void simulateResult(ResultRisk risk) {
    _risk = risk;
    switch (risk) {
      case ResultRisk.low:
        _riskPercent = 0.18;
        _confidence = 0.94;
        break;
      case ResultRisk.medium:
        _riskPercent = 0.62;
        _confidence = 0.87;
        break;
      case ResultRisk.high:
        _riskPercent = 0.86;
        _confidence = 0.91;
        break;
    }
    notifyListeners();
  }

  void setFromPrediction({
    required String result,
    required double confidence,
  }) {
    final normalized = result.trim().toLowerCase();
    switch (normalized) {
      case 'benign':
        _risk = ResultRisk.low;
        _riskPercent = 0.18;
        break;
      case 'melanoma':
        _risk = ResultRisk.high;
        _riskPercent = 0.86;
        break;
      case 'basal_cell_carcinoma':
        _risk = ResultRisk.medium;
        _riskPercent = 0.62;
        break;
      default:
        _risk = ResultRisk.medium;
        _riskPercent = 0.62;
        break;
    }

    _confidence = confidence;
    _showDetails = false;
    notifyListeners();
  }
}