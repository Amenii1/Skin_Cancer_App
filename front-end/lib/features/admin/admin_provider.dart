import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

enum AdminSection {
  overview,
  users,
  dermatologists,
  appointments,
  analyses,
  alerts,
}

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  AdminSection _section = AdminSection.overview;

  String _userSearch = '';
  String _userRoleFilter = 'all';
  String _analysisFilter = 'all';
  String _appointmentDateFilter = '';
  String _appointmentPatientFilter = '';
  String _appointmentDoctorFilter = '';

  AdminOverview overview = AdminOverview.empty();
  List<AdminUserItem> users = const [];
  List<AdminDermatologistItem> dermatologists = const [];
  List<AdminAppointmentItem> appointments = const [];
  List<AdminAnalysisItem> analyses = const [];
  List<AdminAlertItem> alerts = const [];
  List<AdminEventItem> events = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminSection get section => _section;
  String get userSearch => _userSearch;
  String get userRoleFilter => _userRoleFilter;
  String get analysisFilter => _analysisFilter;
  String get appointmentDateFilter => _appointmentDateFilter;
  String get appointmentPatientFilter => _appointmentPatientFilter;
  String get appointmentDoctorFilter => _appointmentDoctorFilter;

  Future<void> loadAll(String? token) async {
    if (token == null || token.isEmpty) {
      _errorMessage = 'Session admin introuvable.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: token);
      final responses = await Future.wait([
        api.getJson('/admin/overview'),
        api.getJson(_buildUsersPath()),
        api.getJson('/admin/dermatologists'),
        api.getJson(_buildAppointmentsPath()),
        api.getJson(_buildAnalysesPath()),
        api.getJson('/admin/alerts'),
      ]);

      overview = AdminOverview.fromJson(responses[0]);
      users = _parseList(
        responses[1]['users'],
        (item) => AdminUserItem.fromJson(item),
      );
      dermatologists = _parseList(
        responses[2]['dermatologists'],
        (item) => AdminDermatologistItem.fromJson(item),
      );
      appointments = _parseList(
        responses[3]['appointments'],
        (item) => AdminAppointmentItem.fromJson(item),
      );
      analyses = _parseList(
        responses[4]['analyses'],
        (item) => AdminAnalysisItem.fromJson(item),
      );

      final alertsResp = responses[5];
      alerts = _parseList(
        alertsResp['suspicious_cases'],
        (item) => AdminAlertItem.fromJson(item),
      );
      events = _parseList(
        alertsResp['events'],
        (item) => AdminEventItem.fromJson(item),
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Impossible de charger le tableau de bord admin.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSection(String? token) async {
    await loadAll(token);
  }

  void setSection(AdminSection value) {
    _section = value;
    notifyListeners();
  }

  Future<void> setUserSearch(String token, String value) async {
    _userSearch = value.trim();
    notifyListeners();
    await loadAll(token);
  }

  Future<void> setUserRoleFilter(String token, String value) async {
    _userRoleFilter = value;
    notifyListeners();
    await loadAll(token);
  }

  Future<void> setAnalysisFilter(String token, String value) async {
    _analysisFilter = value;
    notifyListeners();
    await loadAll(token);
  }

  Future<void> setAppointmentFilters(
    String token, {
    String? date,
    String? patient,
    String? doctor,
  }) async {
    if (date != null) _appointmentDateFilter = date.trim();
    if (patient != null) _appointmentPatientFilter = patient.trim();
    if (doctor != null) _appointmentDoctorFilter = doctor.trim();
    notifyListeners();
    await loadAll(token);
  }

  Future<bool> toggleUserStatus(String token, AdminUserItem user) async {
    try {
      final api = ApiClient(accessToken: token);
      await api.patchJson(
        '/admin/users/${user.id}/status',
        body: {'is_active': !user.isActive},
      );
      await loadAll(token);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Mise a jour du statut impossible.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String token, int userId) async {
    try {
      final api = ApiClient(accessToken: token);
      await api.deleteJson('/admin/users/$userId');
      await loadAll(token);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Suppression utilisateur impossible.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment(String token, int appointmentId) async {
    try {
      final api = ApiClient(accessToken: token);
      await api.deleteJson('/admin/appointments/$appointmentId');
      await loadAll(token);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Suppression du rendez-vous impossible.';
      notifyListeners();
      return false;
    }
  }

  String _buildUsersPath() {
    final params = <String, String>{};
    if (_userSearch.isNotEmpty) params['search'] = _userSearch;
    if (_userRoleFilter != 'all') params['role'] = _userRoleFilter;
    return _withQuery('/admin/users', params);
  }

  String _buildAppointmentsPath() {
    final params = <String, String>{};
    if (_appointmentDateFilter.isNotEmpty) {
      params['appointment_date'] = _appointmentDateFilter;
    }
    if (_appointmentPatientFilter.isNotEmpty) {
      params['patient'] = _appointmentPatientFilter;
    }
    if (_appointmentDoctorFilter.isNotEmpty) {
      params['dermatologist'] = _appointmentDoctorFilter;
    }
    return _withQuery('/admin/appointments', params);
  }

  String _buildAnalysesPath() {
    final params = <String, String>{};
    if (_analysisFilter != 'all') params['prediction'] = _analysisFilter;
    return _withQuery('/admin/analyses', params);
  }

  String _withQuery(String path, Map<String, String> params) {
    if (params.isEmpty) return path;
    final uri = Uri(path: path, queryParameters: params);
    return uri.toString();
  }

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => parse(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class AdminOverview {
  final int patients;
  final int dermatologists;
  final int analyses;
  final int appointments;
  final int cancerCases;
  final int nonCancerCases;
  final List<UsagePoint> usage;
  final List<AdminAlertItem> suspiciousCases;
  final List<AdminEventItem> recentEvents;

  const AdminOverview({
    required this.patients,
    required this.dermatologists,
    required this.analyses,
    required this.appointments,
    required this.cancerCases,
    required this.nonCancerCases,
    required this.usage,
    required this.suspiciousCases,
    required this.recentEvents,
  });

  factory AdminOverview.empty() => const AdminOverview(
        patients: 0,
        dermatologists: 0,
        analyses: 0,
        appointments: 0,
        cancerCases: 0,
        nonCancerCases: 0,
        usage: [],
        suspiciousCases: [],
        recentEvents: [],
      );

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final stats = Map<String, dynamic>.from(json['stats'] ?? const {});
    final distribution =
        Map<String, dynamic>.from(json['case_distribution'] ?? const {});
    final usageRaw = json['usage_over_time'] as List? ?? const [];
    final suspiciousRaw = json['suspicious_cases'] as List? ?? const [];
    final eventsRaw = json['recent_events'] as List? ?? const [];

    return AdminOverview(
      patients: _intValue(stats['patients']),
      dermatologists: _intValue(stats['dermatologists']),
      analyses: _intValue(stats['analyses']),
      appointments: _intValue(stats['appointments']),
      cancerCases: _intValue(distribution['cancer']),
      nonCancerCases: _intValue(distribution['non_cancer']),
      usage: usageRaw
          .whereType<Map>()
          .map((item) => UsagePoint.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      suspiciousCases: suspiciousRaw
          .whereType<Map>()
          .map((item) => AdminAlertItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      recentEvents: eventsRaw
          .whereType<Map>()
          .map((item) => AdminEventItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class UsagePoint {
  final String date;
  final int count;

  const UsagePoint({required this.date, required this.count});

  factory UsagePoint.fromJson(Map<String, dynamic> json) => UsagePoint(
        date: json['date']?.toString() ?? '',
        count: _intValue(json['count']),
      );
}

class AdminUserItem {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String phone;
  final String subtitle;

  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.phone,
    required this.subtitle,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    final role = json['role']?.toString() ?? 'patient';
    final subtitle = switch (role) {
      'doctor' => json['specialite']?.toString() ?? 'Dermatologue',
      'admin' => 'Administrateur',
      _ => json['city']?.toString() ?? 'Patient',
    };
    return AdminUserItem(
      id: _intValue(json['id']),
      name: json['name']?.toString() ?? 'Utilisateur',
      email: json['email']?.toString() ?? '',
      role: role,
      isActive: json['is_active'] == true,
      phone: json['telephone']?.toString() ?? '',
      subtitle: subtitle,
    );
  }
}

class AdminDermatologistItem {
  final int id;
  final int userId;
  final String name;
  final String email;
  final String speciality;
  final String city;
  final bool isActive;
  final int availabilityCount;
  final int appointmentsCount;
  final int reviewsCount;
  final double? averageRating;
  final List<AvailabilityItem> availability;
  final List<ReviewItem> reviews;

  const AdminDermatologistItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.speciality,
    required this.city,
    required this.isActive,
    required this.availabilityCount,
    required this.appointmentsCount,
    required this.reviewsCount,
    required this.averageRating,
    required this.availability,
    required this.reviews,
  });

  factory AdminDermatologistItem.fromJson(Map<String, dynamic> json) =>
      AdminDermatologistItem(
        id: _intValue(json['id']),
        userId: _intValue(json['user_id']),
        name: json['name']?.toString() ?? 'Dermatologue',
        email: json['email']?.toString() ?? '',
        speciality: json['specialite']?.toString() ?? 'Dermatologie',
        city: json['ville']?.toString() ?? '-',
        isActive: json['is_active'] == true,
        availabilityCount: _intValue(json['availability_count']),
        appointmentsCount: _intValue(json['appointments_count']),
        reviewsCount: _intValue(json['reviews_count']),
        averageRating: _doubleValue(json['average_rating']),
        availability: (json['availability'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => AvailabilityItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        reviews: (json['reviews'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => ReviewItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
      );
}

class AvailabilityItem {
  final String date;
  final String start;
  final String end;
  final bool isReserved;

  const AvailabilityItem({
    required this.date,
    required this.start,
    required this.end,
    required this.isReserved,
  });

  factory AvailabilityItem.fromJson(Map<String, dynamic> json) => AvailabilityItem(
        date: json['date']?.toString() ?? '',
        start: json['heure_debut']?.toString() ?? '',
        end: json['heure_fin']?.toString() ?? '',
        isReserved: json['is_reserved'] == true,
      );
}

class ReviewItem {
  final String diagnostic;
  final String comment;
  final int? rating;

  const ReviewItem({
    required this.diagnostic,
    required this.comment,
    required this.rating,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        diagnostic: json['diagnostic']?.toString() ?? 'Avis',
        comment: json['commentaire']?.toString() ?? '',
        rating: json['rating'] == null ? null : _intValue(json['rating']),
      );
}

class AdminAppointmentItem {
  final int id;
  final String patientName;
  final String doctorName;
  final String doctorSpeciality;
  final String status;
  final String date;
  final String start;
  final String end;

  const AdminAppointmentItem({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.doctorSpeciality,
    required this.status,
    required this.date,
    required this.start,
    required this.end,
  });

  factory AdminAppointmentItem.fromJson(Map<String, dynamic> json) =>
      AdminAppointmentItem(
        id: _intValue(json['id']),
        patientName: json['patient_name']?.toString() ?? 'Patient',
        doctorName: json['doctor_name']?.toString() ?? 'Dermatologue',
        doctorSpeciality: json['doctor_specialite']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        date: json['disponibilite_date']?.toString() ??
            json['date_rdv']?.toString() ??
            '',
        start: json['heure_debut']?.toString() ?? '',
        end: json['heure_fin']?.toString() ?? '',
      );
}

class AdminAnalysisItem {
  final int id;
  final String patientName;
  final String patientEmail;
  final String prediction;
  final String result;
  final double? confidence;
  final String bodyZone;
  final String createdAt;
  final bool isSuspicious;

  const AdminAnalysisItem({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.prediction,
    required this.result,
    required this.confidence,
    required this.bodyZone,
    required this.createdAt,
    required this.isSuspicious,
  });

  factory AdminAnalysisItem.fromJson(Map<String, dynamic> json) =>
      AdminAnalysisItem(
        id: _intValue(json['id']),
        patientName: json['patient_name']?.toString() ?? 'Patient',
        patientEmail: json['patient_email']?.toString() ?? '',
        prediction: json['prediction']?.toString() ?? 'unknown',
        result: json['result']?.toString() ?? 'Pending',
        confidence: _doubleValue(json['confidence']),
        bodyZone: json['body_zone_label']?.toString() ?? 'Unknown zone',
        createdAt: json['created_at']?.toString() ?? '',
        isSuspicious: json['is_suspicious'] == true,
      );
}

class AdminAlertItem {
  final int id;
  final String patientName;
  final String result;
  final String createdAt;
  final double? confidence;

  const AdminAlertItem({
    required this.id,
    required this.patientName,
    required this.result,
    required this.createdAt,
    required this.confidence,
  });

  factory AdminAlertItem.fromJson(Map<String, dynamic> json) => AdminAlertItem(
        id: _intValue(json['id']),
        patientName: json['patient_name']?.toString() ?? 'Patient',
        result: json['result']?.toString() ?? 'Suspicious case',
        createdAt: json['created_at']?.toString() ?? '',
        confidence: _doubleValue(json['confidence']),
      );
}

class AdminEventItem {
  final int id;
  final String title;
  final String body;
  final String kind;
  final String createdAt;

  const AdminEventItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
  });

  factory AdminEventItem.fromJson(Map<String, dynamic> json) => AdminEventItem(
        id: _intValue(json['id']),
        title: json['title']?.toString() ?? 'Event',
        body: json['body']?.toString() ?? '',
        kind: json['kind']?.toString() ?? 'event',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

int _intValue(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _doubleValue(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}
