import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/user_model.dart';
import '../../core/api/api_client.dart';

const _kAccessTokenKey = 'access_token';

enum AuthStatus { idle, loading, success, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  UserModel? _currentUser;
  String? _accessToken;

  // Champs UI
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptPolicy = false;
  final bool _biometricEnabled = false;
  UserRole _selectedRole = UserRole.patient;

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirm => _obscureConfirm;
  bool get acceptPolicy => _acceptPolicy;
  UserRole get selectedRole => _selectedRole;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPatient => _currentUser?.isPatient ?? false;
  bool get isDermatologue => _currentUser?.isDermatologue ?? false;

  // Toggles UI
  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirm() {
    _obscureConfirm = !_obscureConfirm;
    notifyListeners();
  }

  void togglePolicy() {
    _acceptPolicy = !_acceptPolicy;
    notifyListeners();
  }

  void setRole(UserRole role) {
    _selectedRole = role;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persistToken(String? token) async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_kAccessTokenKey);
    } else {
      await p.setString(_kAccessTokenKey, token);
    }
  }

  void _setUserFromProfile(
    Map<String, dynamic> profileResp, {
    required String emailFallback,
  }) {
    final id = profileResp['id']?.toString() ?? '';
    final nom = profileResp['nom']?.toString() ?? '';
    final rawEmail = profileResp['email']?.toString().trim();
    final respEmail =
        (rawEmail != null && rawEmail.isNotEmpty) ? rawEmail : emailFallback;
    final roleStr = profileResp['role']?.toString() ?? 'patient';

    final role = roleStr == 'doctor' ? UserRole.dermatologue : UserRole.patient;

    final patientOrDoctorInfo = roleStr == 'doctor'
        ? profileResp['doctor_info']
        : profileResp['patient_info'];
    final speciality = patientOrDoctorInfo?['specialite']?.toString();
    final cabinetAddress = patientOrDoctorInfo?['adresse']?.toString();

    final phone = profileResp['telephone']?.toString() ?? '';

    DateTime? dateOfBirth;
    if (roleStr == 'patient' && patientOrDoctorInfo is Map) {
      final ds = patientOrDoctorInfo['date_naissance']?.toString();
      if (ds != null && ds.isNotEmpty) {
        final parsed = DateTime.tryParse(ds);
        if (parsed != null) {
          dateOfBirth = DateTime(parsed.year, parsed.month, parsed.day);
        }
      }
    }

    String? rpps;
    if (roleStr == 'doctor' && patientOrDoctorInfo is Map) {
      rpps = patientOrDoctorInfo['numero_rpps']?.toString();
    }

    _currentUser = UserModel(
      id: id.isEmpty ? 'usr_${DateTime.now().millisecondsSinceEpoch}' : id,
      fullName: nom.isEmpty ? 'Utilisateur' : nom,
      email: respEmail,
      phone: phone,
      role: role,
      speciality: speciality,
      cabinetAddress: cabinetAddress,
      rppsNumber: rpps,
      dateOfBirth: dateOfBirth,
      isVerified: true,
    );
  }

  /// Restaure la session après redémarrage (token stocké localement).
  Future<bool> restoreSession() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_kAccessTokenKey);
    if (token == null || token.isEmpty) return false;
    _accessToken = token;
    try {
      final authedApi = ApiClient(accessToken: _accessToken);
      final profileResp = await authedApi.getJson('/profile/');
      _setUserFromProfile(profileResp, emailFallback: '');
      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (_) {
      _accessToken = null;
      _currentUser = null;
      await _persistToken(null);
      notifyListeners();
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _errorMessage = 'Veuillez remplir tous les champs.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    if (!_isValidEmail(email)) {
      _errorMessage = 'Adresse email invalide.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final api = ApiClient();
      final loginResp = await api.postJson(
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final token = loginResp['access_token']?.toString();
      if (token == null || token.isEmpty) {
        throw const ApiException(message: 'Token manquant', statusCode: null);
      }

      _accessToken = token;

      final authedApi = ApiClient(accessToken: _accessToken);
      final profileResp = await authedApi.getJson('/profile/');

      _setUserFromProfile(profileResp, emailFallback: email);
      await _persistToken(token);

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      _accessToken = null;
      _currentUser = null;
      await _persistToken(null);
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur de connexion. Vérifie l’URL du backend.';
      _accessToken = null;
      _currentUser = null;
      await _persistToken(null);
      notifyListeners();
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    DateTime? dateOfBirth,
    String? speciality,
    String? rppsNumber,
    String? cabinetAddress,
  }) async {
    // Validations communes
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _errorMessage = 'Veuillez remplir tous les champs.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    if (!_isValidEmail(email)) {
      _errorMessage = 'Adresse email invalide.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      _errorMessage = 'Le mot de passe doit contenir au moins 8 caractères.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    if (password != confirmPassword) {
      _errorMessage = 'Les mots de passe ne correspondent pas.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
    if (!_acceptPolicy) {
      _errorMessage = 'Veuillez accepter la politique de confidentialité.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    // Validations dermatologue
    if (_selectedRole == UserRole.dermatologue) {
      if (rppsNumber == null || rppsNumber.isEmpty) {
        _errorMessage = 'Le numéro RPPS est obligatoire.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
      if (rppsNumber.length != 11) {
        _errorMessage = 'Le numéro RPPS doit contenir 11 chiffres.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    }
    // Validate date of birth (optional, but reasonable age if provided)
    if (dateOfBirth != null) {
      final age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;
      if (age < 13 || age > 120) {
        _errorMessage = 'Âge non réaliste (13-120 ans).';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final backendRole =
          _selectedRole == UserRole.patient ? 'patient' : 'doctor';

      final api = ApiClient();
      final body = <String, dynamic>{
        'nom': fullName,
        'email': email,
        'password': password,
        'role': backendRole,
      };
      if (phone.trim().isNotEmpty) {
        body['telephone'] = phone.trim();
      }
      if (_selectedRole == UserRole.patient && dateOfBirth != null) {
        body['date_naissance'] =
            '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
      }
      if (_selectedRole == UserRole.dermatologue) {
        if (speciality != null && speciality.trim().isNotEmpty) {
          body['specialite'] = speciality.trim();
        }
        if (cabinetAddress != null && cabinetAddress.trim().isNotEmpty) {
          body['adresse_cabinet'] = cabinetAddress.trim();
        }
        if (rppsNumber != null && rppsNumber.trim().isNotEmpty) {
          body['numero_rpps'] = rppsNumber.trim();
        }
      }
      await api.postJson('/auth/register', body: body);

      // Connexion automatique après création de compte.
      return await login(email: email, password: password);
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur d’inscription. Vérifie l’URL du backend.';
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> logout() async {
    _status = AuthStatus.idle;
    _errorMessage = null;
    _accessToken = null;
    _currentUser = null;
    await _persistToken(null);
    notifyListeners();
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    _obscurePassword = true;
    _obscureConfirm = true;
    _acceptPolicy = false;
    notifyListeners();
  }

  // ── Update Profile ────────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? speciality,
    String? cabinetAddress,
    String? rppsNumber,
  }) async {
    if (_accessToken == null) return false;
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);
      final body = <String, dynamic>{
        'nom': name,
        'telephone': phone,
      };
      if (_currentUser?.isDermatologue ?? false) {
        if (speciality != null) body['specialite'] = speciality;
        if (cabinetAddress != null) body['adresse_cabinet'] = cabinetAddress;
        if (rppsNumber != null) body['numero_rpps'] = rppsNumber;
      }

      await api.putJson('/profile/update', body: body);

      // Refresh local user data
      final profileResp = await api.getJson('/profile/');
      _setUserFromProfile(profileResp, emailFallback: _currentUser?.email ?? '');

      _status = AuthStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur lors de la mise à jour du profil.';
      notifyListeners();
      return false;
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
