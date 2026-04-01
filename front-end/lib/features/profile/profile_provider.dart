import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/models/user_model.dart';

class ProfileProvider extends ChangeNotifier {
  // Infos personnelles
  String fullName = 'Thomas Bouchard';
  String email = 'thomas.bouchard@email.com';
  String phone = '+33 6 12 34 56 78';
  String birthDate = '15/03/1990';
  String bloodType = 'A+';

  // Sécurité
  bool biometricEnabled = true;
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
    try {
      final api = ApiClient(accessToken: _accessToken);
      final profile = await api.getJson('/profile/');

      fullName = profile['nom']?.toString() ?? fullName;
      email = profile['email']?.toString() ?? email;

      final roleStr = profile['role']?.toString() ?? 'patient';
      _role = roleStr == 'doctor' ? UserRole.dermatologue : UserRole.patient;

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

  void toggleBiometric() {
    biometricEnabled = !biometricEnabled;
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
      await api.putJson(
        '/profile/update',
        body: {
          'nom': name,
          'email': email,
        },
      );
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
