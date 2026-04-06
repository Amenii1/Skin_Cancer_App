import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../dashboard/dashboard_provider.dart';

class MedicalRecordEntry {
  final int id;
  final DateTime? observationDate;
  final DateTime? createdAt;
  final String result;
  final double confidence;
  final String zoneLabel;
  final List<String> symptoms;
  final String imageUrl;

  const MedicalRecordEntry({
    required this.id,
    required this.observationDate,
    required this.createdAt,
    required this.result,
    required this.confidence,
    required this.zoneLabel,
    required this.symptoms,
    required this.imageUrl,
  });

  RiskLevel get risk {
    switch (result.trim().toLowerCase()) {
      case 'melanoma':
        return RiskLevel.high;
      case 'basal_cell_carcinoma':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}

class MedicalRecordZoneGroup {
  final String zoneId;
  final String zoneLabel;
  final List<MedicalRecordEntry> entries;

  const MedicalRecordZoneGroup({
    required this.zoneId,
    required this.zoneLabel,
    required this.entries,
  });
}

class MedicalRecordProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  String _patientName = 'Patient';
  final List<MedicalRecordEntry> _entries = [];
  final List<MedicalRecordZoneGroup> _zones = [];

  bool get loading => _loading;
  String? get error => _error;
  String get patientName => _patientName;
  List<MedicalRecordEntry> get entries => List.unmodifiable(_entries);
  List<MedicalRecordZoneGroup> get zones => List.unmodifiable(_zones);

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: accessToken);
      final response = await api.getJson('/image/medical-record');

      final patient = (response['patient'] as Map?)?.cast<String, dynamic>() ?? const {};
      final patientName = patient['nom']?.toString().trim();
      if (patientName != null && patientName.isNotEmpty) {
        _patientName = patientName.split(' ').first;
      }

      final rawEntries = (response['entries'] as List?) ?? const [];
      _entries
        ..clear()
        ..addAll(rawEntries.map(_entryFromRaw));

      final rawZones = (response['zones'] as List?) ?? const [];
      _zones
        ..clear()
        ..addAll(
          rawZones.map((raw) {
            final map = (raw as Map).cast<String, dynamic>();
            final rawZoneEntries = (map['entries'] as List?) ?? const [];
            return MedicalRecordZoneGroup(
              zoneId: map['body_zone_id']?.toString() ?? 'unknown',
              zoneLabel: map['body_zone_label']?.toString() ?? 'Zone non précisée',
              entries: rawZoneEntries.map(_entryFromRaw).toList(),
            );
          }),
        );
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Impossible de charger le dossier médical.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  MedicalRecordEntry _entryFromRaw(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    final symptomsRaw = (map['symptoms'] as List?) ?? const [];
    final confidenceRaw = map['confidence'];

    return MedicalRecordEntry(
      id: (map['id'] as num?)?.toInt() ?? 0,
      observationDate: DateTime.tryParse(map['observation_date']?.toString() ?? ''),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      result: map['result']?.toString() ?? 'benign',
      confidence: confidenceRaw is num ? confidenceRaw.toDouble() : 0,
      zoneLabel: map['body_zone_label']?.toString() ?? 'Zone non précisée',
      symptoms: symptomsRaw.map((item) => item.toString()).toList(),
      imageUrl: map['image_url']?.toString() ?? '',
    );
  }
}
