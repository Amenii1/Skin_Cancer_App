import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class DoctorSlot {
  final String id;
  final DateTime dateTime;
  final String time;
  final bool isReserved;
  final String? reservationId;
  final String? status;
  final String? patientName;
  final String? patientInitials;
  final String? reason;
  final String? riskLevel;
  final Color? riskColor;

  DoctorSlot({
    required this.id,
    required this.dateTime,
    required this.time,
    required this.isReserved,
    this.reservationId,
    this.status,
    this.patientName,
    this.patientInitials,
    this.reason,
    this.riskLevel,
    this.riskColor,
  });
}

class DoctorAgendaProvider extends ChangeNotifier {
  List<DoctorSlot> _slots = [];
  bool _isLoading = false;
  String? _accessToken;

  List<DoctorSlot> get slots => _slots;
  bool get isLoading => _isLoading;

  Future<void> fetchAgenda(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    _isLoading = true;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);

      // 1. Fetch all availability slots
      final rawSlots = await api.getJsonList('/disponibilites/doctor/my');

      // 2. Fetch all reservations to match patient info
      final rawRes = await api.getJsonList('/reservations/doctor');
      final reservations =
          rawRes.map((r) => r as Map<String, dynamic>).toList();

      _slots = rawSlots.map((s) {
        final m = s as Map<String, dynamic>;
        final id = m['id']?.toString() ?? '';
        final dateStr = m['date']?.toString() ?? '';
        final timeStr = m['heure_debut']?.toString() ?? '';

        final dt = DateTime.tryParse(dateStr) ?? DateTime.now();
        final timeFormatted = timeStr.substring(0, 5).replaceAll(':', 'h');

        final isReserved = m['is_reserved'] as bool? ?? false;

        Map<String, dynamic>? res;
        if (isReserved) {
          res = reservations.firstWhere(
            (r) => r['disponibilite_id']?.toString() == id,
            orElse: () => {},
          );
        }

        String? patientName = res?['patient_name']?.toString();
        String? initials;
        if (patientName != null) {
          final parts = patientName.split(' ');
          initials = parts
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join('')
              .toUpperCase();
        }

        return DoctorSlot(
          id: id,
          dateTime: dt,
          time: timeFormatted,
          isReserved: isReserved,
          reservationId: res?['id']?.toString(),
          status: res?['status']?.toString(),
          patientName: patientName,
          patientInitials: initials,
          reason: 'Consultation',
          riskLevel: 'Normal',
          riskColor: Colors.blue,
        );
      }).toList();

      _slots.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    } catch (e) {
      debugPrint('Error fetching agenda: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateReservationStatus(
      String reservationId, String status) async {
    if (_accessToken == null) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      await api
          .putJson('/reservations/$reservationId?status=$status', body: {});
      await fetchAgenda(_accessToken);
    } catch (e) {
      debugPrint('Error updating reservation status: $e');
    }
  }

  Future<void> addSlot(DateTime date, TimeOfDay time) async {
    if (_accessToken == null) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";

      // End time is +30 min by default
      final endMin = time.minute + 30;
      final endHour = time.hour + (endMin ~/ 60);
      final endTimeStr =
          "${(endHour % 24).toString().padLeft(2, '0')}:${(endMin % 60).toString().padLeft(2, '0')}:00";

      await api.postJson('/disponibilites/', body: {
        'date': dateStr,
        'heure_debut': timeStr,
        'heure_fin': endTimeStr,
      });
      await fetchAgenda(_accessToken);
    } catch (e) {
      debugPrint('Error adding slot: $e');
    }
  }

  Future<void> deleteSlot(String id) async {
    if (_accessToken == null) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      await api.deleteJson('/disponibilites/$id');
      await fetchAgenda(_accessToken);
    } catch (e) {
      debugPrint('Error deleting slot: $e');
    }
  }
}
