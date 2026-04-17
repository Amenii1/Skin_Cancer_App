import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum AppointmentStatus { pending, accepted, refused, completed }

enum DiagnosticStatus { pending, reviewed }

class PatientAppointment {
  final String id;
  final String patientId;
  final String patientName;
  final String patientInitials;
  final String reason;
  final DateTime dateTime;
  final String patientEmail;
  final String patientPhone;
  final String patientVille;
  final String riskLevel;
  final Color riskColor;
  AppointmentStatus status;
  String? doctorNote;

  PatientAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientInitials,
    required this.reason,
    required this.dateTime,
    required this.patientEmail,
    required this.patientPhone,
    required this.patientVille,
    required this.riskLevel,
    required this.riskColor,
    this.status = AppointmentStatus.pending,
    this.doctorNote,
  });
}

class PatientDiagnostic {
  final String id;
  final String patientId;
  final String patientName;
  final String patientInitials;
  final String zone;
  final double riskPercent;
  final Color riskColor;
  final String riskLabel;
  final DateTime date;
  final String imageUrl;
  final List<String> abcdeFlags;
  DiagnosticStatus status;
  String? doctorOpinion;

  PatientDiagnostic({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientInitials,
    required this.zone,
    required this.riskPercent,
    required this.riskColor,
    required this.riskLabel,
    required this.date,
    required this.imageUrl,
    required this.abcdeFlags,
    this.status = DiagnosticStatus.pending,
    this.doctorOpinion,
  });
}

class DoctorDashboardProvider extends ChangeNotifier {
  int _selectedTab = 0;
  String? _accessToken;

  int get selectedTab => _selectedTab;

  void setTab(int tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  final List<PatientAppointment> appointments = [];
  final List<PatientDiagnostic> diagnostics = [];

  static String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'P';
  }

  static Color _riskColorFromConfidence(double? c) {
    final p = c ?? 0;
    if (p >= 0.6) return AppColors.riskHigh;
    if (p >= 0.35) return AppColors.riskMedium;
    return AppColors.riskLow;
  }

  static String _riskLabelFromConfidence(double? c) {
    final p = c ?? 0;
    if (p >= 0.6) return 'Élevé';
    if (p >= 0.35) return 'Modéré';
    return 'Faible';
  }

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    try {
      final api = ApiClient(accessToken: _accessToken);

      // Fetch Stats
      _stats = await api.getJson('/stats/dashboard');

      final reservations = await api.getJsonList('/reservations/doctor');
      appointments
        ..clear()
        ..addAll(
          reservations.map((raw) {
            final m = (raw as Map).cast<String, dynamic>();
            final id = m['id']?.toString() ?? '';
            final dt = DateTime.tryParse(m['date_rdv']?.toString() ?? '') ??
                DateTime.now();
            final status = _fromStatus(m['status']?.toString() ?? 'pending');
            final pname = m['patient_name']?.toString() ?? 'Patient';
            final riskLabel = m['patient_risk']?.toString() ?? 'Faible';
            Color riskColor = AppColors.riskLow;
            if (riskLabel == 'Élevé') riskColor = AppColors.riskHigh;
            if (riskLabel == 'Modéré') riskColor = AppColors.riskMedium;

            return PatientAppointment(
              id: id,
              patientId: m['patient_id']?.toString() ?? '',
              patientName: pname,
              patientInitials: _initialsFromName(pname),
              reason: 'Consultation dermatologique',
              dateTime: dt,
              patientEmail: m['patient_email']?.toString() ?? '',
              patientPhone: m['patient_phone']?.toString() ?? '',
              patientVille: m['patient_ville']?.toString() ?? '',
              riskLevel: riskLabel,
              riskColor: riskColor,
              status: status,
            );
          }),
        );

      final pendingResp = await api.getJson('/image/doctor/pending');
      final pendingList = (pendingResp['images'] as List?) ?? const [];

      final avisList = await api.getJsonList('/avis/doctor');

      diagnostics.clear();

      for (final raw in pendingList) {
        final m = (raw as Map).cast<String, dynamic>();
        final conf = (m['confidence'] as num?)?.toDouble();
        final p = (conf ?? 0).clamp(0.0, 1.0);
        final pname = m['patient_name']?.toString() ?? 'Patient';
        final created = DateTime.tryParse(m['created_at']?.toString() ?? '');
        diagnostics.add(
          PatientDiagnostic(
            id: m['id']?.toString() ?? '',
            patientId: m['patient_id']?.toString() ?? '',
            patientName: pname,
            patientInitials: _initialsFromName(pname),
            zone: m['zone']?.toString() ?? m['result']?.toString() ?? 'Lésion',
            riskPercent: p,
            riskColor: _riskColorFromConfidence(conf),
            riskLabel:
                m['result']?.toString() ?? _riskLabelFromConfidence(conf),
            date: created ?? DateTime.now(),
            imageUrl: m['image_url']?.toString() ?? '',
            abcdeFlags: const [],
            status: DiagnosticStatus.pending,
          ),
        );
      }

      for (final raw in avisList) {
        final m = (raw as Map).cast<String, dynamic>();
        final conf = (m['confidence'] as num?)?.toDouble();
        final p = (conf ?? 0).clamp(0.0, 1.0);
        final pname = m['patient_name']?.toString() ?? 'Patient';
        final obs = DateTime.tryParse(m['observation_date']?.toString() ?? '');
        diagnostics.add(
          PatientDiagnostic(
            id: m['image_id']?.toString() ?? '',
            patientId: m['patient_id']?.toString() ?? '',
            patientName: pname,
            patientInitials: _initialsFromName(pname),
            zone: m['diagnostic']?.toString() ?? 'Lésion',
            riskPercent: p,
            riskColor: _riskColorFromConfidence(conf),
            riskLabel:
                m['result']?.toString() ?? _riskLabelFromConfidence(conf),
            date: obs ?? DateTime.now(),
            imageUrl: m['image_url']?.toString() ?? '',
            abcdeFlags: const [],
            status: DiagnosticStatus.reviewed,
            doctorOpinion: m['commentaire']?.toString(),
          ),
        );
      }

      notifyListeners();
    } catch (_) {
      // keep existing UI data
    }
  }

  int get pendingAppointments =>
      appointments.where((a) => a.status == AppointmentStatus.pending).length;

  int get todayAppointments {
    final now = DateTime.now();
    return appointments
        .where((a) =>
            a.dateTime.day == now.day &&
            a.dateTime.month == now.month &&
            a.dateTime.year == now.year)
        .length;
  }

  int get pendingDiagnostics =>
      diagnostics.where((d) => d.status == DiagnosticStatus.pending).length;

  Future<void> acceptAppointment(String id) async {
    final appt = appointments.firstWhere((a) => a.id == id);
    appt.status = AppointmentStatus.accepted;
    if (_accessToken != null) {
      try {
        final api = ApiClient(accessToken: _accessToken);
        await api.putJson('/reservations/$id?status=accepted', body: {});
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> refuseAppointment(String id) async {
    final appt = appointments.firstWhere((a) => a.id == id);
    appt.status = AppointmentStatus.refused;
    if (_accessToken != null) {
      try {
        final api = ApiClient(accessToken: _accessToken);
        await api.putJson('/reservations/$id?status=refused', body: {});
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> submitOpinion(String imageId, String opinion) async {
    final diag = diagnostics.firstWhere((d) => d.id == imageId);
    diag.doctorOpinion = opinion;
    diag.status = DiagnosticStatus.reviewed;
    if (_accessToken != null) {
      try {
        final api = ApiClient(accessToken: _accessToken);
        await api.postJson(
          '/avis/$imageId',
          body: {
            'commentaire': opinion,
            'diagnostic': 'Avis dermatologue',
            'rating': 5,
          },
        );
      } catch (_) {}
    }
    await syncFromBackend(_accessToken);
  }

  String formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);

    if (diff.inHours < 24 && dt.day == now.day) {
      return 'Aujourd\'hui ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1 || (diff.inHours < 48 && dt.day == now.day + 1)) {
      return 'Demain ${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
    }
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
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
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} · '
        '${dt.hour.toString().padLeft(2, '0')}h${dt.minute.toString().padLeft(2, '0')}';
  }

  String formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} jours';
  }

  Color statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.pending:
        return AppColors.riskMedium;
      case AppointmentStatus.accepted:
        return AppColors.riskLow;
      case AppointmentStatus.refused:
        return AppColors.riskHigh;
      case AppointmentStatus.completed:
        return AppColors.primary;
    }
  }

  String statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.accepted:
        return 'Accepté';
      case AppointmentStatus.refused:
        return 'Refusé';
      case AppointmentStatus.completed:
        return 'Terminé';
    }
  }

  AppointmentStatus _fromStatus(String status) {
    switch (status) {
      case 'accepted':
        return AppointmentStatus.accepted;
      case 'refused':
        return AppointmentStatus.refused;
      case 'completed':
        return AppointmentStatus.completed;
      default:
        return AppointmentStatus.pending;
    }
  }
}
