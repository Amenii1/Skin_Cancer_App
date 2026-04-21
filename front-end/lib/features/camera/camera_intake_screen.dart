import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../analysis/result_provider.dart';
import '../auth/auth_provider.dart';
import 'camera_provider.dart';

class CameraIntakeScreen extends StatefulWidget {
  const CameraIntakeScreen({super.key});

  @override
  State<CameraIntakeScreen> createState() => _CameraIntakeScreenState();
}

class _CameraIntakeScreenState extends State<CameraIntakeScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _loadingOptions = true;
  String? _optionsError;
  bool _showFront = true;
  String? _selectedZoneId;
  final Set<String> _selectedSymptoms = <String>{};
  List<Map<String, String>> _zones = const [];
  List<String> _symptoms = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOptions());
  }

  Future<void> _loadOptions() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.accessToken == null) {
      setState(() {
        _loadingOptions = false;
        _optionsError = 'Veuillez vous connecter pour analyser une image.';
      });
      return;
    }

    try {
      final api = ApiClient(accessToken: auth.accessToken);
      final response = await api.getJson('/image/intake-options');
      final zonesRaw = (response['body_map_options'] as List?) ?? const [];
      final symptomsRaw = (response['symptom_options'] as List?) ?? const [];

      setState(() {
        _zones = zonesRaw.map((raw) {
          final map = (raw as Map).cast<String, dynamic>();
          return {
            'id': map['id']?.toString() ?? '',
            'label': map['label']?.toString() ?? '',
            'view': map['view']?.toString() ?? 'front',
          };
        }).where((zone) => zone['id']!.isNotEmpty).toList();
        _symptoms = symptomsRaw.map((item) => item.toString()).toList();
        _loadingOptions = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _loadingOptions = false;
        _optionsError = e.message;
      });
    } catch (_) {
      setState(() {
        _loadingOptions = false;
        _optionsError = 'Impossible de charger le formulaire médical.';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (_) {
      _showError('Impossible d’accéder à cette source d’image.');
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final cameraProvider = context.read<CameraProvider>();
    final resultProvider = context.read<ResultProvider>();

    if (_imageBytes == null) {
      _showError('Ajoutez une photo avant de lancer l’analyse.');
      return;
    }
    if (_selectedZoneId == null) {
      _showError('Sélectionnez la zone exacte sur la body map.');
      return;
    }
    if (!auth.isLoggedIn || auth.accessToken == null) {
      _showError('Veuillez vous connecter avant l’analyse.');
      return;
    }

    final now = DateTime.now();
    final observationDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await cameraProvider.capture(
        analysisTask: () async {
          final api = ApiClient(accessToken: auth.accessToken);
          final upload = await api.postMultipartImage(
            path: '/image/upload',
            imageBytes: _imageBytes!,
            observationDate: observationDate,
            fields: {
              'body_zone_id': _selectedZoneId!,
              'symptoms': jsonEncode(_selectedSymptoms.toList()),
            },
          );

          final imageId = (upload['image_id'] as num?)?.toInt();
          if (imageId == null) {
            throw const ApiException(message: 'Réponse image invalide');
          }

          final prediction = await api.postEmpty('/prediction/$imageId');
          final confidenceRaw = prediction['confidence'];
          final zoneLabel = prediction['body_zone_label']?.toString() ??
              _selectedZoneLabel ??
              'Zone non précisée';

          resultProvider.setFromPrediction(
            imageId: imageId,
            result: prediction['result']?.toString() ?? 'benign',
            confidence: confidenceRaw is num ? confidenceRaw.toDouble() : 0,
            zoneLabel: zoneLabel,
            symptoms: _selectedSymptoms.toList(),
          );
        },
      );

      if (mounted) {
        context.go('/result');
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Échec de l’analyse. Vérifiez le backend et le réseau.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.riskHigh,
      ),
    );
  }

  List<Map<String, String>> get _activeZones =>
      _zones.where((zone) => zone['view'] == (_showFront ? 'front' : 'back')).toList();

  Map<String, Rect> get _activeHitboxes {
    if (_showFront) {
      return {
        'head_front': const Rect.fromLTWH(70, 0, 60, 55),
        'neck_front': const Rect.fromLTWH(80, 55, 40, 20),
        'chest_front': const Rect.fromLTWH(55, 75, 90, 70),
        'left_arm_front': const Rect.fromLTWH(10, 75, 45, 110),
        'right_arm_front': const Rect.fromLTWH(145, 75, 45, 110),
        'abdomen_front': const Rect.fromLTWH(60, 145, 80, 60),
        'left_leg_front': const Rect.fromLTWH(55, 205, 45, 130),
        'right_leg_front': const Rect.fromLTWH(100, 205, 45, 130),
      };
    }
    return {
      'head_back': const Rect.fromLTWH(70, 0, 60, 55),
      'upper_back': const Rect.fromLTWH(55, 75, 90, 60),
      'lower_back': const Rect.fromLTWH(60, 135, 80, 60),
      'left_arm_back': const Rect.fromLTWH(10, 75, 45, 110),
      'right_arm_back': const Rect.fromLTWH(145, 75, 45, 110),
      'gluteal': const Rect.fromLTWH(60, 195, 80, 50),
      'left_leg_back': const Rect.fromLTWH(55, 245, 45, 90),
      'right_leg_back': const Rect.fromLTWH(100, 245, 45, 90),
    };
  }

  String? get _selectedZoneLabel {
    for (final zone in _zones) {
      if (zone['id'] == _selectedZoneId) {
        return zone['label'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        title: const Text(
          'Nouvelle analyse',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: _loadingOptions
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildImageSection(),
                const SizedBox(height: 18),
                if (_optionsError != null) _buildErrorCard(_optionsError!),
                if (_optionsError == null) ...[
                  _buildBodyMapSection(),
                  const SizedBox(height: 18),
                  _buildSymptomsSection(),
                  const SizedBox(height: 18),
                  _buildSubmitButton(cameraProvider.isProcessing),
                ],
              ],
            ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. Ajouter une image',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prenez une photo directement dans l\'application ou choisissez une image de votre galerie.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 220,
              width: double.infinity,
              color: AppColors.bgSoft,
              child: _imageBytes == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 34,
                            color: AppColors.textHint,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Aucune image selectionnee',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Utilisez la camera pour une prise instantanee.',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_imageBytes!, fit: BoxFit.cover),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: IconButton(
                              onPressed: () => setState(() => _imageBytes = null),
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              tooltip: 'Retirer l\'image',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(
                    _imageBytes == null ? 'Prendre une photo' : 'Reprendre une photo',
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choisir en galerie'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La photo prise dans l\'application est utilisee directement pour l\'analyse. Aucun upload manuel supplementaire n\'est necessaire.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMapSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Sélectionner la partie du corps',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez la zone exacte avant d’obtenir le résultat.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ToggleChip(
                label: 'Face',
                selected: _showFront,
                onTap: () => setState(() => _showFront = true),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Dos',
                selected: !_showFront,
                onTap: () => setState(() => _showFront = false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTapDown: (details) {
                for (final entry in _activeHitboxes.entries) {
                  if (entry.value.contains(details.localPosition)) {
                    setState(() => _selectedZoneId = entry.key);
                    break;
                  }
                }
              },
              child: SizedBox(
                width: 200,
                height: 340,
                child: CustomPaint(
                  painter: _IntakeBodyPainter(
                    isFront: _showFront,
                    selectedZoneId: _selectedZoneId,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedZoneLabel == null
                        ? 'Touchez la zone exacte où se trouve la lésion.'
                        : 'Zone sélectionnée : $_selectedZoneLabel',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activeZones.map((zone) {
              final selected = zone['id'] == _selectedZoneId;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  zone['label']!,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. Cocher les symptômes observés',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Symptômes cliniquement pertinents pour les lésions pigmentées et cancers cutanés.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          ..._symptoms.map((symptom) {
            final selected = _selectedSymptoms.contains(symptom);
            return CheckboxListTile(
              value: selected,
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: Text(
                symptom,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              onChanged: (_) {
                setState(() {
                  if (selected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    if (symptom == 'Aucun symptôme ressenti') {
                      _selectedSymptoms
                        ..clear()
                        ..add(symptom);
                    } else {
                      _selectedSymptoms.remove('Aucun symptôme ressenti');
                      _selectedSymptoms.add(symptom);
                    }
                  }
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool processing) {
    return ElevatedButton.icon(
      onPressed: processing ? null : _submit,
      icon: processing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.psychology_alt_rounded),
      label: Text(processing ? 'Analyse en cours...' : 'Lancer l’analyse'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.riskHigh.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Nunito',
          color: AppColors.riskHigh,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _IntakeBodyPainter extends CustomPainter {
  final bool isFront;
  final String? selectedZoneId;

  const _IntakeBodyPainter({
    required this.isFront,
    required this.selectedZoneId,
  });

  Color _zoneColor(String zoneId) {
    if (selectedZoneId == zoneId) {
      return AppColors.primary;
    }
    return AppColors.border;
  }

  void _drawZone(Canvas canvas, Path path, String zoneId) {
    final color = _zoneColor(zoneId);
    final selected = selectedZoneId == zoneId;

    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: selected ? 0.78 : 0.5),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = selected ? AppColors.primary : Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.5 : 1.0,
    );

    if (selected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    if (isFront) {
      _paintFront(canvas, cx);
    } else {
      _paintBack(canvas, cx);
    }
  }

  void _paintFront(Canvas canvas, double cx) {
    _drawZone(
      canvas,
      Path()..addOval(Rect.fromCenter(center: Offset(cx, 28), width: 52, height: 54)),
      'head_front',
    );
    _drawZone(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, 63), width: 20, height: 18),
            const Radius.circular(4),
          ),
        ),
      'neck_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 44, 72)
        ..lineTo(cx + 44, 72)
        ..lineTo(cx + 38, 148)
        ..lineTo(cx - 38, 148)
        ..close(),
      'chest_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 44, 74)
        ..lineTo(cx - 60, 80)
        ..lineTo(cx - 58, 150)
        ..lineTo(cx - 48, 150)
        ..lineTo(cx - 44, 130)
        ..close(),
      'left_arm_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 60, 150)
        ..lineTo(cx - 64, 155)
        ..lineTo(cx - 60, 210)
        ..lineTo(cx - 50, 208)
        ..lineTo(cx - 48, 150)
        ..close(),
      'left_arm_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 44, 74)
        ..lineTo(cx + 60, 80)
        ..lineTo(cx + 58, 150)
        ..lineTo(cx + 48, 150)
        ..lineTo(cx + 44, 130)
        ..close(),
      'right_arm_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 60, 150)
        ..lineTo(cx + 64, 155)
        ..lineTo(cx + 60, 210)
        ..lineTo(cx + 50, 208)
        ..lineTo(cx + 48, 150)
        ..close(),
      'right_arm_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 38, 148)
        ..lineTo(cx + 38, 148)
        ..lineTo(cx + 34, 205)
        ..lineTo(cx - 34, 205)
        ..close(),
      'abdomen_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 34, 205)
        ..lineTo(cx - 4, 205)
        ..lineTo(cx - 8, 300)
        ..lineTo(cx - 36, 298)
        ..close(),
      'left_leg_front',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 34, 205)
        ..lineTo(cx + 4, 205)
        ..lineTo(cx + 8, 300)
        ..lineTo(cx + 36, 298)
        ..close(),
      'right_leg_front',
    );
  }

  void _paintBack(Canvas canvas, double cx) {
    _drawZone(
      canvas,
      Path()..addOval(Rect.fromCenter(center: Offset(cx, 28), width: 52, height: 54)),
      'head_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 44, 72)
        ..lineTo(cx + 44, 72)
        ..lineTo(cx + 40, 140)
        ..lineTo(cx - 40, 140)
        ..close(),
      'upper_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 44, 74)
        ..lineTo(cx - 60, 80)
        ..lineTo(cx - 58, 150)
        ..lineTo(cx - 48, 150)
        ..lineTo(cx - 44, 130)
        ..close(),
      'left_arm_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 60, 150)
        ..lineTo(cx - 64, 155)
        ..lineTo(cx - 60, 210)
        ..lineTo(cx - 50, 208)
        ..lineTo(cx - 48, 150)
        ..close(),
      'left_arm_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 44, 74)
        ..lineTo(cx + 60, 80)
        ..lineTo(cx + 58, 150)
        ..lineTo(cx + 48, 150)
        ..lineTo(cx + 44, 130)
        ..close(),
      'right_arm_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 60, 150)
        ..lineTo(cx + 64, 155)
        ..lineTo(cx + 60, 210)
        ..lineTo(cx + 50, 208)
        ..lineTo(cx + 48, 150)
        ..close(),
      'right_arm_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 40, 140)
        ..lineTo(cx + 40, 140)
        ..lineTo(cx + 36, 200)
        ..lineTo(cx - 36, 200)
        ..close(),
      'lower_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 36, 200)
        ..lineTo(cx + 36, 200)
        ..lineTo(cx + 34, 250)
        ..lineTo(cx - 34, 250)
        ..close(),
      'gluteal',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx - 34, 250)
        ..lineTo(cx - 4, 250)
        ..lineTo(cx - 8, 330)
        ..lineTo(cx - 36, 328)
        ..close(),
      'left_leg_back',
    );
    _drawZone(
      canvas,
      Path()
        ..moveTo(cx + 34, 250)
        ..lineTo(cx + 4, 250)
        ..lineTo(cx + 8, 330)
        ..lineTo(cx + 36, 328)
        ..close(),
      'right_leg_back',
    );
  }

  @override
  bool shouldRepaint(covariant _IntakeBodyPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.selectedZoneId != selectedZoneId;
  }
}
