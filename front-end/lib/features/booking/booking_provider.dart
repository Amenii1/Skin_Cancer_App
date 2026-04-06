import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../dermatologist/dermatologist_provider.dart';

enum BookingStatus { idle, loading, confirmed, error }

class TimeSlot {
  final String id;
  final String label;
  final DateTime dateTime;
  bool isAvailable;
  bool isSelected;

  TimeSlot({
    required this.id,
    required this.label,
    required this.dateTime,
    this.isAvailable = true,
    this.isSelected = false,
  });
}

class BookingDay {
  final DateTime date;
  final String dayLabel;
  final String dateLabel;
  bool isSelected;
  final List<TimeSlot> slots;

  BookingDay({
    required this.date,
    required this.dayLabel,
    required this.dateLabel,
    this.isSelected = false,
    required this.slots,
  });
}

class BookingProvider extends ChangeNotifier {
  DermatologistModel? _doctor;
  BookingStatus _status = BookingStatus.idle;
  int _selectedDayIndex = 0;
  TimeSlot? _selectedSlot;
  String _reason = '';
  String _notes = '';
  String? _accessToken;

  DermatologistModel? get doctor => _doctor;
  BookingStatus get status => _status;
  int get selectedDayIndex => _selectedDayIndex;
  TimeSlot? get selectedSlot => _selectedSlot;
  String get reason => _reason;
  bool get isLoading => _status == BookingStatus.loading;
  bool get isConfirmed => _status == BookingStatus.confirmed;
  bool get canConfirm => _selectedSlot != null && _reason.isNotEmpty;

  // Jours + créneaux chargés depuis backend
  List<BookingDay> days = [];

  List<BookingDay> _generateDays() {
    const dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    const monthNames = [
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

    final now = DateTime.now();
    final result = <BookingDay>[];

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i + 1));
      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      result.add(BookingDay(
        date: date,
        dayLabel: dayNames[date.weekday % 7],
        dateLabel: '${date.day} ${monthNames[date.month - 1]}',
        isSelected: i == 0,
        slots: isWeekend
            ? _generateSlots(date, ['09:00', '10:00', '11:00'])
            : _generateSlots(date, [
                '08:30',
                '09:00',
                '09:30',
                '10:00',
                '10:30',
                '11:00',
                '14:00',
                '14:30',
                '15:00',
                '15:30',
                '16:00',
                '16:30'
              ]),
      ));
    }
    return result;
  }

  List<TimeSlot> _generateSlots(DateTime date, List<String> times) {
    return times.asMap().entries.map((e) {
      final parts = e.value.split(':');
      final dt = DateTime(date.year, date.month, date.day, int.parse(parts[0]),
          int.parse(parts[1]));
      // Simuler quelques créneaux non disponibles
      final unavailable = [1, 3, 7];
      return TimeSlot(
        id: '${date.day}_${e.key}',
        label: e.value,
        dateTime: dt,
        isAvailable: !unavailable.contains(e.key),
      );
    }).toList();
  }

  BookingDay get selectedDay {
    if (days.isEmpty) {
      final now = DateTime.now();
      return BookingDay(
        date: now,
        dayLabel: _dayLabel(now.weekday),
        dateLabel: '${now.day}/${now.month}',
        slots: <TimeSlot>[],
      );
    }
    return days[_selectedDayIndex.clamp(0, days.length - 1)];
  }

  void bindAccessToken(String? token) {
    _accessToken = token;
  }

  void setDoctor(DermatologistModel doctor) {
    _doctor = doctor;
    _selectedSlot = null;
    _status = BookingStatus.idle;
    _loadDisponibilites();
    notifyListeners();
  }

  void selectDay(int index) {
    if (days.isEmpty || index < 0 || index >= days.length) return;
    days[_selectedDayIndex].isSelected = false;
    _selectedDayIndex = index;
    days[_selectedDayIndex].isSelected = true;
    _selectedSlot = null;
    notifyListeners();
  }

  void selectSlot(TimeSlot slot) {
    if (days.isEmpty) return;
    if (!slot.isAvailable) return;
    // Désélectionner l'ancien
    for (final day in days) {
      for (final s in day.slots) {
        s.isSelected = false;
      }
    }
    slot.isSelected = true;
    _selectedSlot = slot;
    notifyListeners();
  }

  void setReason(String value) {
    _reason = value;
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  Future<bool> confirmBooking() async {
    if (!canConfirm || _accessToken == null || _selectedSlot == null) {
      return false;
    }
    _status = BookingStatus.loading;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);
      await api
          .postEmpty('/reservations/?disponibilite_id=${_selectedSlot!.id}');
      _status = BookingStatus.confirmed;
      notifyListeners();
      return true;
    } on ApiException {
      _status = BookingStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _status = BookingStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = BookingStatus.idle;
    _selectedSlot = null;
    _reason = '';
    _notes = '';
    notifyListeners();
  }

  String formatConfirmedDate() {
    if (_selectedSlot == null) return '';
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    final dt = _selectedSlot!.dateTime;
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} '
        'à ${dt.hour.toString().padLeft(2, '0')}h'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDisponibilites() async {
    final doctorId = int.tryParse(_doctor?.id ?? '');
    if (_accessToken == null || doctorId == null) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      final list = await api.getJsonList('/disponibilites/$doctorId');

      final grouped = <String, List<TimeSlot>>{};
      for (final raw in list) {
        final m = (raw as Map).cast<String, dynamic>();
        final dispoId = m['id']?.toString() ?? '';
        final date = DateTime.tryParse(m['date']?.toString() ?? '');
        final start = m['heure_debut']?.toString() ?? '';
        if (date == null || start.isEmpty) continue;
        final hm = start.split(':');
        final h = int.tryParse(hm[0]) ?? 0;
        final min = int.tryParse(hm[1]) ?? 0;
        final dt = DateTime(date.year, date.month, date.day, h, min);
        final key = '${date.year}-${date.month}-${date.day}';
        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(
          TimeSlot(
            id: dispoId,
            label:
                '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
            dateTime: dt,
            isAvailable: true,
          ),
        );
      }

      final keys = grouped.keys.toList()..sort();
      days = keys.asMap().entries.map((entry) {
        final i = entry.key;
        final k = entry.value;
        final p = k.split('-').map(int.parse).toList();
        final date = DateTime(p[0], p[1], p[2]);
        return BookingDay(
          date: date,
          dayLabel: _dayLabel(date.weekday),
          dateLabel: '${date.day}/${date.month}',
          isSelected: i == 0,
          slots: grouped[k]!..sort((a, b) => a.dateTime.compareTo(b.dateTime)),
        );
      }).toList();
      _selectedDayIndex = 0;
      notifyListeners();
    } catch (_) {
      // keep empty days if API fails
    }
  }

  String _dayLabel(int weekday) {
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return dayNames[weekday - 1];
  }
}
