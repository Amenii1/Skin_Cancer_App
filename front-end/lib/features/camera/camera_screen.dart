import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../auth/auth_provider.dart';
import '../analysis/result_provider.dart';
import 'camera_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scanAnim;
  late Animation<double> _pulseAnim;

  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Prendre une photo ─────────────────────────────────────
  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _imageBytes = bytes);
        await _processImage();
      }
    } catch (e) {
      _showError('Caméra non disponible. Utilisez la galerie.');
    }
  }

  // ── Choisir depuis la galerie ─────────────────────────────
  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _imageBytes = bytes);
        await _processImage();
      }
    } catch (e) {
      _showError('Impossible d\'accéder à la galerie.');
    }
  }

  // ── Traitement IA (FastAPI) ────────────────────────────────
  Future<void> _processImage() async {
    final prov = context.read<CameraProvider>();
    final auth = context.read<AuthProvider>();
    final resultProv = context.read<ResultProvider>();

    final bytes = _imageBytes;
    if (bytes == null) {
      _showError('Image introuvable. Réessaie.');
      return;
    }

    final now = DateTime.now();
    final observationDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      await prov.capture(analysisTask: () async {
        if (!auth.isLoggedIn || auth.accessToken == null) {
          throw const ApiException(
            message: 'Veuillez vous connecter avant l’analyse',
            statusCode: 401,
          );
        }

        final api = ApiClient(accessToken: auth.accessToken);

        final uploadResp = await api.postMultipartImage(
          path: '/image/upload',
          imageBytes: bytes,
          observationDate: observationDate,
        );

        final imageIdRaw = uploadResp['image_id'];
        final imageId = imageIdRaw is int
            ? imageIdRaw
            : int.tryParse(imageIdRaw.toString());

        if (imageId == null) {
          throw const ApiException(
            message: 'image_id manquant dans la réponse',
            statusCode: 500,
          );
        }

        final predictionResp = await api.postEmpty('/prediction/$imageId');

        final result = predictionResp['result']?.toString() ?? 'benign';
        final confidenceRaw = predictionResp['confidence'];
        final confidence =
            confidenceRaw is num ? confidenceRaw.toDouble() : 0.0;

        resultProv.setFromPrediction(
          result: result,
          confidence: confidence,
        );
      });

      if (mounted) context.go('/result');
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Échec de l’analyse. Vérifie le backend et le réseau.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.riskHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond / prévisualisation image
          _buildBackground(),

          // Overlay vignette
          _buildVignette(),

          // UI principale
          SafeArea(
            child: Column(children: [
              _buildTopBar(context, prov),
              const Spacer(),
              _buildScanFrame(),
              const SizedBox(height: 16),
              _buildHint(),
              const Spacer(),
              _buildIndicators(prov),
              const SizedBox(height: 20),
              _buildBottomControls(context, prov),
              const SizedBox(height: 36),
            ]),
          ),

          // Overlay processing
          if (prov.isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // ── Fond / image capturée ─────────────────────────────────
  Widget _buildBackground() {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: BoxFit.cover,
      );
    }
    // Fond simulé quand pas d'image
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Color(0xFF1A2B3C),
            Color(0xFF0D1B2A),
            Colors.black,
          ],
        ),
      ),
      child: CustomPaint(painter: _ViewfinderBgPainter()),
    );
  }

  // ── Vignette ──────────────────────────────────────────────
  Widget _buildVignette() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.75,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, CameraProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/dashboard'),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          const Column(children: [
            Text('Scanner une lésion',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 16,
                  fontWeight: FontWeight.w700, color: Colors.white,
                )),
            Text('DermaScan AI',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 11,
                  color: Colors.white54, letterSpacing: 1.2,
                )),
          ]),
          // Flash toggle (visuel seulement sur web)
          GestureDetector(
            onTap: prov.toggleFlash,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: prov.flashOn
                    ? AppColors.accent.withOpacity(0.3)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: prov.flashOn
                      ? AppColors.accent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.2),
                ),
              ),
              child: Icon(
                prov.flashOn
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: prov.flashOn ? AppColors.accent : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cadre de scan animé ───────────────────────────────────
  Widget _buildScanFrame() {
    return AnimatedBuilder(
      animation: Listenable.merge([_scanCtrl, _pulseCtrl]),
      builder: (_, __) {
        return Transform.scale(
          scale: _pulseAnim.value,
          child: SizedBox(
            width: 240, height: 240,
            child: Stack(children: [
              CustomPaint(
                size: const Size(240, 240),
                painter: _ScanFramePainter(),
              ),
              // Ligne de scan
              Positioned(
                top: 10 + (_scanAnim.value * 200),
                left: 10, right: 10,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              // Grille
              CustomPaint(
                size: const Size(240, 240),
                painter: _GridPainter(),
              ),
              // Point central
              Center(
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ── Indication utilisateur ────────────────────────────────
  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: const Text(
        'Centrez la lésion dans le cadre',
        style: TextStyle(
          fontFamily: 'Nunito', fontSize: 13,
          color: Colors.white70, fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ── Indicateurs qualité / stabilité ──────────────────────
  Widget _buildIndicators(CameraProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(children: [
        Expanded(
          child: _IndicatorBar(
            icon: Icons.wb_sunny_outlined,
            label: 'Qualité',
            value: prov.qualityScore,
            valueLabel: prov.qualityLabel,
            color: prov.qualityColor(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _IndicatorBar(
            icon: Icons.straighten_rounded,
            label: 'Stabilité',
            value: prov.stabilityScore,
            valueLabel: prov.stabilityLabel,
            color: prov.stabilityColor(),
          ),
        ),
      ]),
    );
  }

  // ── Contrôles bas ─────────────────────────────────────────
  Widget _buildBottomControls(BuildContext context, CameraProvider prov) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Galerie
        GestureDetector(
          onTap: prov.isProcessing ? null : _pickFromGallery,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined,
                    color: Colors.white, size: 20),
                SizedBox(height: 2),
                Text('Galerie',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 9,
                      color: Colors.white70,
                    )),
              ],
            ),
          ),
        ),

        // Bouton capture principal
        GestureDetector(
          onTap: prov.isProcessing ? null : _pickFromCamera,
          child: Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20, spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
        ),

        // Retournement caméra
        GestureDetector(
          onTap: prov.toggleCamera,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flip_camera_ios_rounded,
                    color: Colors.white, size: 20),
                SizedBox(height: 2),
                Text('Flip',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 9,
                      color: Colors.white70,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Overlay processing ────────────────────────────────────
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent, strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Analyse IA en cours…',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 16,
                  fontWeight: FontWeight.w700, color: Colors.white,
                )),
            const SizedBox(height: 8),
            Text('Traitement de l\'image',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                )),
          ],
        ),
      ),
    );
  }
}

// ── Widgets réutilisables ─────────────────────────────────────
class _IndicatorBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String valueLabel;
  final Color color;

  const _IndicatorBar({
    required this.icon, required this.label,
    required this.value, required this.valueLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 11,
                  color: Colors.white60,
                )),
            const Spacer(),
            Text(valueLabel,
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 11,
                  fontWeight: FontWeight.w700, color: color,
                )),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value, minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainters ────────────────────────────────────────────
class _ViewfinderBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      final y = size.height / 20 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _ScanFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cornerLen = 28.0;
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void drawCorner(Offset o, bool left, bool top) {
      final xd = left ? 1.0 : -1.0;
      final yd = top ? 1.0 : -1.0;
      canvas.drawLine(o, Offset(o.dx + xd * cornerLen, o.dy), shadowPaint);
      canvas.drawLine(o, Offset(o.dx, o.dy + yd * cornerLen), shadowPaint);
      canvas.drawLine(o, Offset(o.dx + xd * cornerLen, o.dy), paint);
      canvas.drawLine(o, Offset(o.dx, o.dy + yd * cornerLen), paint);
    }

    drawCorner(const Offset(10, 10), true, true);
    drawCorner(Offset(size.width - 10, 10), false, true);
    drawCorner(Offset(10, size.height - 10), true, false);
    drawCorner(Offset(size.width - 10, size.height - 10), false, false);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), 60,
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
  @override
  bool shouldRepaint(_) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(10, size.height / 3),
        Offset(size.width - 10, size.height / 3), paint);
    canvas.drawLine(Offset(10, size.height * 2 / 3),
        Offset(size.width - 10, size.height * 2 / 3), paint);
    canvas.drawLine(Offset(size.width / 3, 10),
        Offset(size.width / 3, size.height - 10), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 10),
        Offset(size.width * 2 / 3, size.height - 10), paint);
  }
  @override
  bool shouldRepaint(_) => false;
}