import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user_model.dart';

const _kBirthDateMs = 'profile_birth_date_ms';

class ProfileProvider extends ChangeNotifier {
  // Infos personnelles
  String fullName = 'Thomas Bouchard';
  String email = 'thomas.bouchard@email.com';
  String phone = '+33 6 12 34 56 78';
  DateTime? birthDate;
  String bloodType = 'A+';

  // Sécurité
  bool notificationsEnabled = true;
  bool dataEncrypted = true;
  bool twoFactorEnabled = false;
  bool autoBackup = true;

  // Statistiques patient
  int totalScans = 0;
  int totalLesions = 0;
  int daysActive = 0;
  String memberSince = '—';

  // Rendez-vous
  final List<Map<String, dynamic>> upcomingAppointments = [];
  String? _accessToken;

  bool _editMode = false;
  bool get editMode => _editMode;

  UserRole _role = UserRole.patient;
  UserRole get role => _role;
  bool get isPatient => _role == UserRole.patient;

  Future<void> syncFromBackend(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    await _loadBirthDateFromPrefs();
    notifyListeners();
    try {
      final api = ApiClient(accessToken: _accessToken);
      final profile = await api.getJson('/profile/');

      fullName = profile['nom']?.toString() ?? fullName;
      email = profile['email']?.toString() ?? email;
      phone = profile['telephone']?.toString() ?? phone;

      final roleStr = profile['role']?.toString() ?? 'patient';
      _role = roleStr == 'doctor' ? UserRole.dermatologue : UserRole.patient;

      if (_role == UserRole.patient) {
        final pi = profile['patient_info'];
        if (pi is Map) {
          final ds = pi['date_naissance']?.toString();
          if (ds != null && ds.isNotEmpty) {
            final parsed = DateTime.tryParse(ds);
            if (parsed != null) {
              birthDate = DateTime(parsed.year, parsed.month, parsed.day);
              await _saveBirthDateToPrefs();
            }
          }
        }
      }

      if (_role == UserRole.patient) {
        final list = await api.getJsonList('/reservations/my');
        upcomingAppointments
          ..clear()
          ..addAll(
            list.map((raw) {
              final m = (raw as Map).cast<String, dynamic>();
              final d = DateTime.tryParse(m['date_rdv']?.toString() ?? '');
              return {
                'doctor': 'Dermatologue',
                'specialty': 'Consultation',
                'date': d == null ? '—' : _fmtDate(d),
                'status': m['status']?.toString() ?? 'pending',
                'address': 'Cabinet',
              };
            }),
          );

        final images = await api.getJson('/image/list');
        final arr = (images['images'] as List?) ?? const [];
        totalScans = arr.length;
        totalLesions = arr.length;
      } else {
        upcomingAppointments.clear();
        totalScans = 0;
        totalLesions = 0;
      }
      notifyListeners();
    } catch (_) {
      // ignore network errors for now
    }
  }

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  void toggleEdit() {
    _editMode = !_editMode;
    notifyListeners();
  }

  void toggleNotifications() {
    notificationsEnabled = !notificationsEnabled;
    notifyListeners();
  }

  void toggleTwoFactor() {
    twoFactorEnabled = !twoFactorEnabled;
    notifyListeners();
  }

  void toggleAutoBackup() {
    autoBackup = !autoBackup;
    notifyListeners();
  }

  Future<void> _loadBirthDateFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    final ms = p.getInt(_kBirthDateMs);
    if (ms != null) {
      birthDate = DateTime.fromMillisecondsSinceEpoch(ms);
    }
  }

  Future<void> _saveBirthDateToPrefs() async {
    final d = birthDate;
    if (d == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kBirthDateMs, d.millisecondsSinceEpoch);
  }

  void setBirthDate(DateTime date) {
    birthDate = date;
    notifyListeners();
    _saveBirthDateToPrefs();
  }

  String get birthDateFormatted {
    if (birthDate == null) return 'Non renseignée';
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
    return '${birthDate!.day} ${months[birthDate!.month - 1]} ${birthDate!.year}';
  }

  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    fullName = name;
    this.email = email;
    this.phone = phone;
    _editMode = false;
    notifyListeners();

    if (_accessToken == null || _accessToken!.isEmpty) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      final body = <String, dynamic>{
        'nom': name,
        'email': email,
        'telephone': phone,
      };
      if (_role == UserRole.patient && birthDate != null) {
        body['date_naissance'] =
            '${birthDate!.year}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}';
      }
      await api.putJson('/profile/update', body: body);
    } catch (_) {
      // keep optimistic UI
    }
  }

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  Color appointmentStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'refused':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9DB5C4);
    }
  }

  String appointmentStatusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'refused':
        return 'Refusé';
      default:
        return 'Inconnu';
    }
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
