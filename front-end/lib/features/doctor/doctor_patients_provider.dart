import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class PatientInfo {
  final String id;
  final String name;
  final String initials;
  final String email;
  final String phone;
  final String ville;
  final int lesionCount;
  final String riskLevel;
  final Color riskColor;
  final String lastVisit;

  PatientInfo({
    required this.id,
    required this.name,
    required this.initials,
    required this.email,
    required this.phone,
    required this.ville,
    required this.lesionCount,
    required this.riskLevel,
    required this.riskColor,
    required this.lastVisit,
  });

  factory PatientInfo.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Inconnu';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    
    Color riskColor = AppColors.riskLow;
    if (json['risk_color'] == 'high') {
      riskColor = AppColors.riskHigh;
    } else if (json['risk_color'] == 'medium') riskColor = AppColors.riskMedium;

    return PatientInfo(
      id: json['id']?.toString() ?? '',
      name: name,
      initials: initials.isEmpty ? 'P' : initials,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      ville: json['ville']?.toString() ?? '',
      lesionCount: json['lesion_count'] as int? ?? 0,
      riskLevel: json['risk_level']?.toString() ?? 'Faible',
      riskColor: riskColor,
      lastVisit: json['last_visit']?.toString() ?? 'Non renseigné',
    );
  }
}

class DoctorPatientsProvider extends ChangeNotifier {
  List<PatientInfo> _patients = [];
  bool _isLoading = false;
  String? _accessToken;

  List<PatientInfo> get patients => _patients;
  bool get isLoading => _isLoading;

  Future<void> fetchPatients(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    _isLoading = true;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);
      final list = await api.getJsonList('/doctor/patients');
      _patients = list.map((json) => PatientInfo.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
