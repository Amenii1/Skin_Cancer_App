import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class DermatologistModel {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int reviewCount;
  final double lat;
  final double lng;
  final String address;
  final String phone;
  final bool available;
  final List<String> availableSlots;
  double? distanceKm;

  DermatologistModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
    required this.available,
    required this.availableSlots,
    this.distanceKm,
  });
}

class DermatologistProvider extends ChangeNotifier {
  String _searchQuery = '';
  int _selectedIndex = -1;
  bool _listView = true;

  Position? _userPosition;
  bool _locationLoading = false;
  String? _locationError;
  String? _recommendationHint;
  String _recommendationMode = 'gps_realtime';

  final List<DermatologistModel> doctors = [];
  String? _accessToken;

  // ───────── GETTERS ─────────
  String get searchQuery => _searchQuery;
  int get selectedIndex => _selectedIndex;
  bool get listView => _listView;
  Position? get userPosition => _userPosition;
  bool get locationLoading => _locationLoading;
  String? get locationError => _locationError;
  String? get recommendationHint => _recommendationHint;
  String get recommendationMode => _recommendationMode;

  // ✅ selected doctor
  DermatologistModel? get selected =>
      (_selectedIndex >= 0 && _selectedIndex < doctors.length)
          ? doctors[_selectedIndex]
          : null;

  // ✅ nearest
  DermatologistModel? get nearest {
    if (doctors.isEmpty) return null;
    final list = doctors.where((d) => d.distanceKm != null).toList();
    if (list.isEmpty) return doctors.first;
    list.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return list.first;
  }

  // ✅ nearest available
  DermatologistModel? get nearestAvailable {
    final list =
        doctors.where((d) => d.distanceKm != null && d.available).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.distanceKm!.compareTo(b.distanceKm!));
    return list.first;
  }

  // ───────── LOCATION + SYNC ─────────
  Future<void> loadDoctorsWithLocation(String token) async {
    _accessToken = token;
    await getUserLocation();
  }

  Future<void> syncFromBackend(String token) async {
    _accessToken = token;
    await _fetchDoctors(
        lat: _userPosition?.latitude, lng: _userPosition?.longitude);
  }

  Future<void> getUserLocation() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      _locationError = 'Session invalide';
      notifyListeners();
      return;
    }

    _locationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Activez le service de localisation';
        await _fetchDoctors();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError = 'Autorisation de localisation refusée';
        await _fetchDoctors();
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        _locationError = 'Position indisponible';
        await _fetchDoctors();
        return;
      }

      _userPosition = pos;
      await _fetchDoctors(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      _locationError = 'Erreur localisation';
      await _fetchDoctors();
    } finally {
      _locationLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDoctors({double? lat, double? lng}) async {
    final api = ApiClient(accessToken: _accessToken);
    final path = (lat != null && lng != null)
        ? '/referral/nearby-dermatologues?lat=$lat&lng=$lng'
        : '/referral/nearby-dermatologues';
    final resp = await api.getJson(path);
    final items = (resp['items'] as List?) ?? [];
    _recommendationHint = resp['hint']?.toString();
    _recommendationMode = resp['mode']?.toString() ?? 'gps_realtime';

    doctors
      ..clear()
      ..addAll(items.map((raw) {
        final m = (raw as Map).cast<String, dynamic>();
        return DermatologistModel(
          id: m['dermatologue_id'].toString(),
          name: m['nom'] ?? 'Dermatologue',
          specialty: m['specialite'] ?? '',
          rating: (m['rating'] ?? 0).toDouble(),
          reviewCount: 0,
          lat: (m['latitude'] ?? 0).toDouble(),
          lng: (m['longitude'] ?? 0).toDouble(),
          address: m['adresse_cabinet'] ?? '',
          phone: (m['phone'] ?? '').toString(),
          available: m['available'] ?? true,
          availableSlots: const [],
          distanceKm: (m['distance_km'] as num?)?.toDouble(),
        );
      }));

    doctors.sort((a, b) {
      final d = (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999);
      if (d != 0) return d;
      return b.rating.compareTo(a.rating);
    });
  }

  // ───────── ACTIONS ─────────
  void select(int index) {
    _selectedIndex = (_selectedIndex == index) ? -1 : index;
    notifyListeners();
  }

  void selectDoctor(DermatologistModel doc) {
    final index = doctors.indexOf(doc);
    if (index != -1) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void toggleView() {
    _listView = !_listView;
    notifyListeners();
  }

  void search(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // ───────── FILTER ─────────
  List<DermatologistModel> get filtered {
    if (_searchQuery.isEmpty) return doctors;
    final q = _searchQuery.toLowerCase();
    return doctors.where((d) {
      return d.name.toLowerCase().contains(q) ||
          d.specialty.toLowerCase().contains(q) ||
          d.address.toLowerCase().contains(q);
    }).toList();
  }

  // ───────── UTILS ─────────
  String formatDistance(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).toInt()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  Color availabilityColor(bool available) =>
      available ? AppColors.riskLow : AppColors.riskMedium;

  String availabilityLabel(bool available) =>
      available ? 'Disponible' : 'Sur RDV';

  // ───────── ACTION BUTTONS ─────────
  Future<void> callDoctor(DermatologistModel doc) async {
    if (doc.phone.isEmpty) return;
    final uri = Uri.parse('tel:${doc.phone}');
    await launchUrl(uri);
  }

  Future<void> openDirections(DermatologistModel doc) async {
    if (doc.lat == 0 && doc.lng == 0) return;

    String url;

    if (_userPosition != null) {
      url =
          'https://www.google.com/maps/dir/${_userPosition!.latitude},${_userPosition!.longitude}/${doc.lat},${doc.lng}';
    } else {
      url =
          'https://www.google.com/maps/search/?api=1&query=${doc.lat},${doc.lng}';
    }

    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  Future<void> bookAppointment(DermatologistModel doc) async {
    final uri = Uri.parse('https://www.doctolib.fr/dermatologue');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
