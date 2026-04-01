import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

enum AppointmentStatus { pending, accepted, refused, completed }

enum DiagnosticStatus { pending, reviewed }

class PatientAppointment {
  final String id;
  final String patientName;
  final String patientInitials;
  final String reason;
  final DateTime dateTime;
  final String riskLevel;
  final Color riskColor;
  AppointmentStatus status;
  String? doctorNote;

  PatientAppointment({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.reason,
    required this.dateTime,
    required this.riskLevel,
    required this.riskColor,
    this.status = AppointmentStatus.pending,
    this.doctorNote,
  });
}

class PatientDiagnostic {
  final String id;
  final String patientName;
  final String patientInitials;
  final String zone;
  final double riskPercent;
  final Color riskColor;
  final String riskLabel;
  final DateTime date;
  DiagnosticStatus status;
  String? doctorOpinion;

  PatientDiagnostic({
    required this.id,
    required this.patientName,
    required this.patientInitials,
    required this.zone,
    required this.riskPercent,
    required this.riskColor,
    required this.riskLabel,
    required this.date,
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

  // ── Rendez-vous ───────────────────────────────────────────
  final List<PatientAppointment> appointments = [];

  // ── Diagnostics en attente d'avis ─────────────────────────
  final List<PatientDiagnostic> diagnostics = [];

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    try {
      final api = ApiClient(accessToken: _accessToken);

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
            return PatientAppointment(
              id: id,
              patientName: 'Patient #${m['patient_id'] ?? '?'}',
              patientInitials: 'P',
              reason: 'Consultation dermatologique',
              dateTime: dt,
              riskLevel: '—',
              riskColor: AppColors.riskMedium,
              status: status,
            );
          }),
        );

      final avis = await api.getJsonList('/avis/doctor');
      diagnostics
        ..clear()
        ..addAll(
          avis.map((raw) {
            final m = (raw as Map).cast<String, dynamic>();
            return PatientDiagnostic(
              id: m['image_id']?.toString() ?? m['id']?.toString() ?? '',
              patientName: 'Patient',
              patientInitials: 'P',
              zone: 'Image #${m['image_id'] ?? '?'}',
              riskPercent: 0.0,
              riskColor: AppColors.riskMedium,
              riskLabel: m['diagnostic']?.toString() ?? 'Avis',
              date: DateTime.now(),
              status: DiagnosticStatus.reviewed,
              doctorOpinion: m['commentaire']?.toString(),
            );
          }),
        );

      notifyListeners();
    } catch (_) {
      // keep existing UI data
    }
  }

  // ── Statistiques ──────────────────────────────────────────
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

  // ── Actions RDV ───────────────────────────────────────────
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

  // ── Actions diagnostic ────────────────────────────────────
  Future<void> submitOpinion(String id, String opinion) async {
    final diag = diagnostics.firstWhere((d) => d.id == id);
    diag.doctorOpinion = opinion;
    diag.status = DiagnosticStatus.reviewed;
    if (_accessToken != null) {
      try {
        final api = ApiClient(accessToken: _accessToken);
        final encoded = Uri.encodeQueryComponent(opinion);
        await api
            .postEmpty('/avis/$id?commentaire=$encoded&diagnostic=reviewed');
      } catch (_) {}
    }
    notifyListeners();
  }

  // ── Formatage date ────────────────────────────────────────
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
