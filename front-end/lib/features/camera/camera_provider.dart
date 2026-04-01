import 'package:flutter/material.dart';

enum CameraState { idle, capturing, processing }

class CameraProvider extends ChangeNotifier {
  CameraState _state = CameraState.idle;
  bool _flashOn = false;
  bool _frontCamera = false;
  double _qualityScore = 0.82;
  double _stabilityScore = 0.91;
  bool _imageCaptured = false;

  CameraState get state => _state;
  bool get flashOn => _flashOn;
  bool get frontCamera => _frontCamera;
  double get qualityScore => _qualityScore;
  double get stabilityScore => _stabilityScore;
  bool get imageCaptured => _imageCaptured;
  bool get isProcessing => _state == CameraState.processing;

  String get qualityLabel {
    if (_qualityScore >= 0.8) return 'Excellente';
    if (_qualityScore >= 0.6) return 'Bonne';
    return 'Faible';
  }

  Color qualityColor() {
    if (_qualityScore >= 0.8) return const Color(0xFF4CAF50);
    if (_qualityScore >= 0.6) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get stabilityLabel {
    if (_stabilityScore >= 0.8) return 'Stable';
    if (_stabilityScore >= 0.5) return 'Mouvement';
    return 'Instable';
  }

  Color stabilityColor() {
    if (_stabilityScore >= 0.8) return const Color(0xFF4CAF50);
    if (_stabilityScore >= 0.5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  void toggleFlash() {
    _flashOn = !_flashOn;
    notifyListeners();
  }

  void toggleCamera() {
    _frontCamera = !_frontCamera;
    notifyListeners();
  }

  Future<void> capture({required Future<void> Function() analysisTask}) async {
    if (_state != CameraState.idle) return;
    _state = CameraState.capturing;
    _imageCaptured = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      _state = CameraState.processing;
      notifyListeners();

      await analysisTask();
    } finally {
      _state = CameraState.idle;
      notifyListeners();
    }
  }

  void reset() {
    _state = CameraState.idle;
    _imageCaptured = false;
    _qualityScore = 0.82;
    _stabilityScore = 0.91;
    notifyListeners();
  }
}