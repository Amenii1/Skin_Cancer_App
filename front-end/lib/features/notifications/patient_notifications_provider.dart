import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class PatientNotificationItem {
  final String id;
  final String title;
  final String body;
  final String kind;
  final bool read;
  final String? imageId;
  final DateTime? createdAt;
  final Map<String, dynamic>? doctor;

  PatientNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.read,
    required this.imageId,
    required this.createdAt,
    required this.doctor,
  });

  factory PatientNotificationItem.fromJson(Map<String, dynamic> json) {
    return PatientNotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      read: json['read'] == true,
      imageId: json['image_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      doctor: json['doctor'] is Map<String, dynamic>
          ? json['doctor'] as Map<String, dynamic>
          : (json['doctor'] is Map ? Map<String, dynamic>.from(json['doctor']) : null),
    );
  }
}

class PatientNotificationsProvider extends ChangeNotifier {
  final List<PatientNotificationItem> _items = [];
  bool _isLoading = false;
  String? _accessToken;

  List<PatientNotificationItem> get items => _items;
  bool get isLoading => _isLoading;
  int get unreadCount => _items.where((e) => !e.read).length;
  List<PatientNotificationItem> get unreadItems =>
      _items.where((e) => !e.read).toList();
  List<PatientNotificationItem> get readItems =>
      _items.where((e) => e.read).toList();

  Future<void> fetchNotifications(String? accessToken) async {
    if (accessToken == null || accessToken.isEmpty) return;
    _accessToken = accessToken;
    _isLoading = true;
    notifyListeners();

    try {
      final api = ApiClient(accessToken: _accessToken);
      final response = await api.getJson('/notifications');
      final raw = (response['notifications'] as List?) ?? const [];
      _items
        ..clear()
        ..addAll(raw.map((e) => PatientNotificationItem.fromJson(
            (e as Map).cast<String, dynamic>())));
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1 || _items[index].read || _accessToken == null) return;

    try {
      final api = ApiClient(accessToken: _accessToken);
      await api.patchJson('/notifications/$id/read', body: {});
      final current = _items[index];
      _items[index] = PatientNotificationItem(
        id: current.id,
        title: current.title,
        body: current.body,
        kind: current.kind,
        read: true,
        imageId: current.imageId,
        createdAt: current.createdAt,
        doctor: current.doctor,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_accessToken == null) return;
    try {
      final api = ApiClient(accessToken: _accessToken);
      await api.postEmpty('/notifications/read-all');
      for (var i = 0; i < _items.length; i++) {
        final current = _items[i];
        _items[i] = PatientNotificationItem(
          id: current.id,
          title: current.title,
          body: current.body,
          kind: current.kind,
          read: true,
          imageId: current.imageId,
          createdAt: current.createdAt,
          doctor: current.doctor,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
