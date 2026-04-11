import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum TrackingRisk { low, medium, high }

class TrackingEntry {
  final String id;
  final DateTime date;
  final TrackingRisk risk;
  final double riskPercent;
  final String notes;
  final List<String> symptoms;

  const TrackingEntry({
    required this.id,
    required this.date,
    required this.risk,
    required this.riskPercent,
    required this.notes,
    required this.symptoms,
  });
}

class TrackingProvider extends ChangeNotifier {
  String lesionId = 'L1';
  String lesionZone = 'Suivi chronologique';
  int _selectedEntry = 0;
  String? _accessToken;

  int get selectedEntry => _selectedEntry;

  final List<TrackingEntry> entries = [];

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    try {
      final api = ApiClient(accessToken: _accessToken);
      final timeline = await api.getJson('/suivi/timeline');
      final points = (timeline['points'] as List?) ?? const [];
      entries
        ..clear()
        ..addAll(
          points.map((raw) {
            final m = (raw as Map).cast<String, dynamic>();
            final date = DateTime.tryParse(
                  m['observation_date']?.toString() ??
                      m['uploaded_at']?.toString() ??
                      '',
                ) ??
                DateTime.now();
            final confidence = (m['confidence'] is num)
                ? (m['confidence'] as num).toDouble()
                : 0.0;
            final result = m['result']?.toString() ?? '';
            final risk = _mapRisk(result);
            final id = m['image_id']?.toString() ?? '0';
            final symptomsRaw = (m['symptoms'] as List?) ?? const [];
            return TrackingEntry(
              id: id,
              date: date,
              risk: risk,
              riskPercent: confidence,
              notes: 'Résultat: ${result.isEmpty ? 'inconnu' : result}',
              symptoms: symptomsRaw.isEmpty
                  ? const ['Aucun symptôme renseigné']
                  : symptomsRaw.map((item) => item.toString()).toList(),
            );
          }),
        );

      if (entries.isNotEmpty) {
        lesionId = 'L${entries.first.id}';
        final firstPoint = (points.first as Map).cast<String, dynamic>();
        final zoneLabel = firstPoint['body_zone_label']?.toString() ?? '';
        lesionZone = zoneLabel.trim().isNotEmpty
            ? zoneLabel
            : 'Suivi chronologique';
        _selectedEntry = 0;
      } else {
        lesionId = 'L1';
        lesionZone = 'Suivi chronologique';
      }
      notifyListeners();
    } catch (_) {
      // garde le dernier état UI
    }
  }

  void selectEntry(int index) {
    _selectedEntry = index;
    notifyListeners();
  }

  TrackingEntry get current => entries[_selectedEntry];
  TrackingEntry get _fallback => TrackingEntry(
        id: '0',
        date: DateTime.now(),
        risk: TrackingRisk.low,
        riskPercent: 0,
        notes: 'Aucune donnée de suivi',
        symptoms: const ['Ajoutez un premier scan'],
      );
  TrackingEntry get safeCurrent =>
      entries.isEmpty ? _fallback : entries[_selectedEntry.clamp(0, entries.length - 1)];

  Color riskColor(TrackingRisk r) {
    switch (r) {
      case TrackingRisk.low: return AppColors.riskLow;
      case TrackingRisk.medium: return AppColors.riskMedium;
      case TrackingRisk.high: return AppColors.riskHigh;
    }
  }

  String riskLabel(TrackingRisk r) {
    switch (r) {
      case TrackingRisk.low: return 'Faible';
      case TrackingRisk.medium: return 'Modéré';
      case TrackingRisk.high: return 'Élevé';
    }
  }

  String formatDate(DateTime d) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  TrackingRisk _mapRisk(String result) {
    final normalized = result.trim().toLowerCase();
    if (normalized.contains('melanoma')) {
      return TrackingRisk.high;
    }
    if (normalized.contains('basal cell carcinoma') ||
        normalized.contains('actinic keratoses') ||
        normalized.contains('keratosis')) {
      return TrackingRisk.medium;
    }
    return TrackingRisk.low;
  }
}
