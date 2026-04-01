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
  bool _biometricEnabled = false;
  UserRole _selectedRole = UserRole.patient;

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirm => _obscureConfirm;
  bool get acceptPolicy => _acceptPolicy;
  bool get biometricEnabled => _biometricEnabled;
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

  void toggleBiometric() {
    _biometricEnabled = !_biometricEnabled;
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

    _currentUser = UserModel(
      id: id.isEmpty ? 'usr_${DateTime.now().millisecondsSinceEpoch}' : id,
      fullName: nom.isEmpty ? 'Utilisateur' : nom,
      email: respEmail,
      phone: '',
      role: role,
      speciality: speciality,
      cabinetAddress: cabinetAddress,
      rppsNumber: null,
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

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final backendRole =
          _selectedRole == UserRole.patient ? 'patient' : 'doctor';

      final api = ApiClient();
      await api.postJson(
        '/auth/register',
        body: {
          'nom': fullName,
          'email': email,
          'password': password,
          'role': backendRole,
        },
      );

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
  void logout() {
    _currentUser = null;
    _accessToken = null;
    _status = AuthStatus.idle;
    _errorMessage = null;
    _obscurePassword = true;
    _obscureConfirm = true;
    _acceptPolicy = false;
    _selectedRole = UserRole.patient;
    notifyListeners();
    _persistToken(null);
  }

  void reset() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    _obscurePassword = true;
    _obscureConfirm = true;
    _acceptPolicy = false;
    notifyListeners();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
