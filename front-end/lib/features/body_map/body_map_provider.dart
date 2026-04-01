import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum ZoneRisk { none, low, medium, high }

class BodyZone {
  final String id;
  final String label;
  ZoneRisk risk;
  int lesionCount;
  bool isSelected;

  BodyZone({
    required this.id,
    required this.label,
    this.risk = ZoneRisk.none,
    this.lesionCount = 0,
    this.isSelected = false,
  });
}

class BodyMapProvider extends ChangeNotifier {
  bool _showFront = true;
  String? _selectedZoneId;

  bool get showFront => _showFront;
  String? get selectedZoneId => _selectedZoneId;

  final List<BodyZone> frontZones = [
    BodyZone(id: 'head', label: 'Tête / Visage',
        risk: ZoneRisk.low, lesionCount: 1),
    BodyZone(id: 'neck', label: 'Cou',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'chest', label: 'Poitrine',
        risk: ZoneRisk.low, lesionCount: 1),
    BodyZone(id: 'leftArm', label: 'Bras gauche',
        risk: ZoneRisk.medium, lesionCount: 2),
    BodyZone(id: 'rightArm', label: 'Bras droit',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'abdomen', label: 'Abdomen',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'leftLeg', label: 'Jambe gauche',
        risk: ZoneRisk.low, lesionCount: 1),
    BodyZone(id: 'rightLeg', label: 'Jambe droite',
        risk: ZoneRisk.none, lesionCount: 0),
  ];

  final List<BodyZone> backZones = [
    BodyZone(id: 'backHead', label: 'Nuque',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'upperBack', label: 'Haut du dos',
        risk: ZoneRisk.high, lesionCount: 1),
    BodyZone(id: 'lowerBack', label: 'Bas du dos',
        risk: ZoneRisk.medium, lesionCount: 1),
    BodyZone(id: 'leftBackArm', label: 'Bras gauche (dos)',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'rightBackArm', label: 'Bras droit (dos)',
        risk: ZoneRisk.low, lesionCount: 1),
    BodyZone(id: 'buttocks', label: 'Fessiers',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'leftBackLeg', label: 'Jambe gauche (dos)',
        risk: ZoneRisk.none, lesionCount: 0),
    BodyZone(id: 'rightBackLeg', label: 'Jambe droite (dos)',
        risk: ZoneRisk.low, lesionCount: 1),
  ];

  List<BodyZone> get activeZones =>
      _showFront ? frontZones : backZones;

  BodyZone? get selectedZone {
    if (_selectedZoneId == null) return null;
    final all = [...frontZones, ...backZones];
    try {
      return all.firstWhere((z) => z.id == _selectedZoneId);
    } catch (_) {
      return null;
    }
  }

  void toggleView() {
    _showFront = !_showFront;
    _selectedZoneId = null;
    notifyListeners();
  }

  void selectZone(String id) {
    _selectedZoneId = _selectedZoneId == id ? null : id;
    notifyListeners();
  }

  Color zoneColor(ZoneRisk risk, {bool selected = false}) {
    if (selected) return AppColors.primary;
    switch (risk) {
      case ZoneRisk.none: return AppColors.border;
      case ZoneRisk.low: return AppColors.riskLow;
      case ZoneRisk.medium: return AppColors.riskMedium;
      case ZoneRisk.high: return AppColors.riskHigh;
    }
  }

  String riskLabel(ZoneRisk risk) {
    switch (risk) {
      case ZoneRisk.none: return 'Aucune lésion';
      case ZoneRisk.low: return 'Risque faible';
      case ZoneRisk.medium: return 'Risque modéré';
      case ZoneRisk.high: return 'Risque élevé';
    }
  }

  int get totalLesions =>
      [...frontZones, ...backZones]
          .fold(0, (sum, z) => sum + z.lesionCount);

  int get highRiskCount =>
      [...frontZones, ...backZones]
          .where((z) => z.risk == ZoneRisk.high)
          .length;
}