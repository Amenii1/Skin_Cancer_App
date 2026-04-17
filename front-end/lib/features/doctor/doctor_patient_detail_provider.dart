import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class PatientAvisHistory {
  final String id;
  final String imageId;
  final String commentaire;
  final DateTime date;
  final String predictionAtTime;
  final String diagnostic;

  PatientAvisHistory({
    required this.id,
    required this.imageId,
    required this.commentaire,
    required this.date,
    required this.predictionAtTime,
    required this.diagnostic,
  });

  factory PatientAvisHistory.fromJson(Map<String, dynamic> json) {
    return PatientAvisHistory(
      id: json['id']?.toString() ?? '',
      imageId: json['image_id']?.toString() ?? '',
      commentaire: json['commentaire']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      predictionAtTime: json['prediction_at_time']?.toString() ?? 'Inconnue',
      diagnostic: json['diagnostic']?.toString() ?? 'Non renseigne',
    );
  }
}

class PatientMedicalRecordItem {
  final String id;
  final String path;
  final String result;
  final double confidence;
  final DateTime createdAt;
  final String? location;
  final DateTime? observationDate;

  PatientMedicalRecordItem({
    required this.id,
    required this.path,
    required this.result,
    required this.confidence,
    required this.createdAt,
    this.location,
    this.observationDate,
  });

  factory PatientMedicalRecordItem.fromJson(Map<String, dynamic> json) {
    return PatientMedicalRecordItem(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      result: json['result']?.toString() ?? 'Non analyse',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      location: json['location']?.toString(),
      observationDate:
          DateTime.tryParse(json['observation_date']?.toString() ?? ''),
    );
  }
}

class PatientAppointmentHistoryItem {
  final String id;
  final DateTime? dateTime;
  final String status;
  final String? startTime;
  final String? endTime;

  PatientAppointmentHistoryItem({
    required this.id,
    required this.dateTime,
    required this.status,
    this.startTime,
    this.endTime,
  });

  factory PatientAppointmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PatientAppointmentHistoryItem(
      id: json['id']?.toString() ?? '',
      dateTime: DateTime.tryParse(json['date_rdv']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'accepted',
      startTime: json['heure_debut']?.toString(),
      endTime: json['heure_fin']?.toString(),
    );
  }
}

class PatientFullDetail {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String ville;
  final DateTime? birthDate;
  final String? gender;
  final String? skinType;
  final String? familyHistory;
  final List<PatientMedicalRecordItem> medicalRecord;
  final List<PatientAvisHistory> avisHistory;
  final List<PatientAppointmentHistoryItem> appointments;

  PatientFullDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.ville,
    this.birthDate,
    this.gender,
    this.skinType,
    this.familyHistory,
    required this.medicalRecord,
    required this.avisHistory,
    required this.appointments,
  });

  factory PatientFullDetail.fromJson(Map<String, dynamic> json) {
    return PatientFullDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Inconnu',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      birthDate: DateTime.tryParse(json['date_naissance']?.toString() ?? ''),
      gender: json['genre']?.toString(),
      skinType: json['type_peau']?.toString(),
      familyHistory: json['antecedents_familiaux']?.toString(),
      medicalRecord: (json['medical_record'] as List? ?? [])
          .map((i) => PatientMedicalRecordItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      avisHistory: (json['avis_history'] as List? ?? [])
          .map((i) => PatientAvisHistory.fromJson(i as Map<String, dynamic>))
          .toList(),
      appointments: (json['appointments'] as List? ?? [])
          .map((i) => PatientAppointmentHistoryItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DoctorPatientDetailProvider extends ChangeNotifier {
  PatientFullDetail? _detail;
  bool _isLoading = false;
  String? _accessToken;

  PatientFullDetail? get detail => _detail;
  bool get isLoading => _isLoading;

  Future<void> fetchPatientDetail(String? accessToken, String patientId) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    _isLoading = true;
    _detail = null;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);
      final data = await api.getJson('/doctor/patients/$patientId');
      _detail = PatientFullDetail.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching patient detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
