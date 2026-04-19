import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum TrackingRisk { low, medium, high }

class TrackingZone {
  final String id;
  final String label;
  final int entryCount;
  final String latestResult;

  const TrackingZone({
    required this.id,
    required this.label,
    required this.entryCount,
    required this.latestResult,
  });
}

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
  String? _selectedZoneId;
  final Map<String, List<TrackingEntry>> _entriesByZone = {};

  int get selectedEntry => _selectedEntry;
  String? get selectedZoneId => _selectedZoneId;

  final List<TrackingEntry> entries = [];
  final List<TrackingZone> zones = [];

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    try {
      final api = ApiClient(accessToken: _accessToken);
      final timeline = await api.getJson('/suivi/timeline');
      final points = (timeline['points'] as List?) ?? const [];
      final rawZones = (timeline['zones'] as List?) ?? const [];

      _entriesByZone.clear();
      zones
        ..clear()
        ..addAll(
          rawZones.map((rawZone) {
            final zoneMap = (rawZone as Map).cast<String, dynamic>();
            final zoneId = zoneMap['body_zone_id']?.toString() ?? 'unknown';
            final zoneLabel =
                zoneMap['body_zone_label']?.toString() ?? 'Zone non précisée';
            final zonePoints = (zoneMap['points'] as List?) ?? const [];
            final zoneEntries = zonePoints
                .map((rawPoint) => _entryFromMap((rawPoint as Map).cast<String, dynamic>()))
                .toList();
            _entriesByZone[zoneId] = zoneEntries;
            return TrackingZone(
              id: zoneId,
              label: zoneLabel,
              entryCount: zoneEntries.length,
              latestResult: zoneMap['latest_result']?.toString() ?? '',
            );
          }),
        );

      if (zones.isNotEmpty) {
        _applyZone(_selectedZoneId ?? zones.first.id);
      } else {
        entries
          ..clear()
          ..addAll(
            points.map((raw) => _entryFromMap((raw as Map).cast<String, dynamic>())),
          );

        if (entries.isNotEmpty) {
          lesionId = 'L${entries.first.id}';
          final firstPoint = (points.first as Map).cast<String, dynamic>();
          final zoneLabel = firstPoint['body_zone_label']?.toString() ?? '';
          lesionZone =
              zoneLabel.trim().isNotEmpty ? zoneLabel : 'Suivi chronologique';
          _selectedEntry = 0;
        } else {
          lesionId = 'L1';
          lesionZone = 'Suivi chronologique';
          _selectedEntry = 0;
        }
      }
      notifyListeners();
    } catch (_) {
      // garde le dernier état UI
    }
  }

  void selectZone(String zoneId) {
    if (_selectedZoneId == zoneId) return;
    _applyZone(zoneId);
    notifyListeners();
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
      case TrackingRisk.low:
        return AppColors.riskLow;
      case TrackingRisk.medium:
        return AppColors.riskMedium;
      case TrackingRisk.high:
        return AppColors.riskHigh;
    }
  }

  String riskLabel(TrackingRisk r) {
    switch (r) {
      case TrackingRisk.low:
        return 'Faible';
      case TrackingRisk.medium:
        return 'Modéré';
      case TrackingRisk.high:
        return 'Élevé';
    }
  }

  String formatDate(DateTime d) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
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

  TrackingEntry _entryFromMap(Map<String, dynamic> m) {
    final date = DateTime.tryParse(
          m['observation_date']?.toString() ?? m['uploaded_at']?.toString() ?? '',
        ) ??
        DateTime.now();
    final confidence =
        (m['confidence'] is num) ? (m['confidence'] as num).toDouble() : 0.0;
    final result = m['result']?.toString() ?? '';
    final symptomsRaw = (m['symptoms'] as List?) ?? const [];

    return TrackingEntry(
      id: m['image_id']?.toString() ?? '0',
      date: date,
      risk: _mapRisk(result),
      riskPercent: confidence,
      notes: 'Résultat: ${result.isEmpty ? 'inconnu' : result}',
      symptoms: symptomsRaw.isEmpty
          ? const ['Aucun symptôme renseigné']
          : symptomsRaw.map((item) => item.toString()).toList(),
    );
  }

  void _applyZone(String zoneId) {
    final resolvedZoneId =
        _entriesByZone.containsKey(zoneId) ? zoneId : (zones.isNotEmpty ? zones.first.id : zoneId);
    _selectedZoneId = resolvedZoneId;
    final zoneEntries = _entriesByZone[resolvedZoneId] ?? const <TrackingEntry>[];
    entries
      ..clear()
      ..addAll(zoneEntries);

    final selectedZone = zones.where((zone) => zone.id == resolvedZoneId);
    final zone = selectedZone.isEmpty ? null : selectedZone.first;
    lesionZone = zone?.label ?? 'Suivi chronologique';
    lesionId = entries.isNotEmpty ? 'L${entries.first.id}' : 'L1';
    _selectedEntry = 0;
  }
}
