import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'doctor_dashboard_provider.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DoctorDashboardProvider>().syncFromBackend(auth.accessToken);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorDashboardProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, auth, prov)),
            SliverToBoxAdapter(child: _buildStats(prov)),
            SliverToBoxAdapter(child: _buildTabBar(prov)),
            SliverToBoxAdapter(
              child: prov.selectedTab == 0
                  ? _buildAppointments(context, prov)
                  : _buildAvis(context, prov),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, AuthProvider auth, DoctorDashboardProvider prov) {
    final user = auth.currentUser;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF534AB7).withOpacity(0.12),
            AppColors.bgWhite,
          ],
        ),
      ),
      child: Row(children: [
        // Avatar médecin
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7F77DD), Color(0xFF534AB7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7F77DD).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user?.initials ?? 'DR',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dr. ${user?.fullName.split(' ').last ?? 'Médecin'}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user?.speciality ?? 'Dermatologue',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
        // Badge vérification
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.riskLow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.riskLow.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.verified_rounded, color: AppColors.riskLow, size: 14),
            SizedBox(width: 4),
            Text('Vérifié',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.riskLow,
                )),
          ]),
        ),
      ]),
    );
  }

  // ── Stats ─────────────────────────────────────────────────
  Widget _buildStats(DoctorDashboardProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(children: [
        _StatCard(
          value: '${prov.todayAppointments}',
          label: 'RDV\naujourd\'hui',
          icon: Icons.today_rounded,
          color: const Color(0xFF7F77DD),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${prov.pendingAppointments}',
          label: 'Demandes\nen attente',
          icon: Icons.pending_actions_rounded,
          color: AppColors.riskMedium,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${prov.pendingDiagnostics}',
          label: 'Avis\ndemandés',
          icon: Icons.rate_review_rounded,
          color: AppColors.riskHigh,
        ),
      ]),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────
  Widget _buildTabBar(DoctorDashboardProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          _TabBtn(
            label: 'Rendez-vous',
            icon: Icons.calendar_month_rounded,
            active: prov.selectedTab == 0,
            badge: prov.pendingAppointments,
            onTap: () => prov.setTab(0),
          ),
          _TabBtn(
            label: 'Avis',
            icon: Icons.rate_review_rounded,
            active: prov.selectedTab == 1,
            badge: prov.pendingDiagnostics,
            onTap: () => prov.setTab(1),
          ),
        ]),
      ),
    );
  }

  // ── Liste rendez-vous ─────────────────────────────────────
  Widget _buildAppointments(
      BuildContext context, DoctorDashboardProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ...prov.appointments.map((appt) => _AppointmentCard(
              appt: appt,
              prov: prov,
              onAccept: () => prov.acceptAppointment(appt.id),
              onRefuse: () => _showRefuseDialog(context, appt, prov),
            )),
      ]),
    );
  }

  // ── Liste diagnostics ─────────────────────────────────────
  Widget _buildAvis(BuildContext context, DoctorDashboardProvider prov) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        ...prov.diagnostics.map((diag) => _DiagnosticCard(
              diag: diag,
              prov: prov,
              onGiveOpinion: () => _showOpinionDialog(context, diag, prov),
            )),
      ]),
    );
  }

  // ── Dialog refus RDV ──────────────────────────────────────
  void _showRefuseDialog(BuildContext context, PatientAppointment appt,
      DoctorDashboardProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refuser le rendez-vous',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
        content: Text(
          'Voulez-vous refuser le rendez-vous de ${appt.patientName} ?',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                )),
          ),
          TextButton(
            onPressed: () {
              prov.refuseAppointment(appt.id);
              Navigator.pop(context);
            },
            child: const Text('Refuser',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  color: AppColors.riskHigh,
                )),
          ),
        ],
      ),
    );
  }

  // ── Dialog avis diagnostic ────────────────────────────────
  void _showOpinionDialog(BuildContext context, PatientDiagnostic diag,
      DoctorDashboardProvider prov) {
    final ctrl = TextEditingController(text: diag.doctorOpinion ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header dialog ────────────────────
                Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: diag.riskColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.biotech_rounded,
                        color: diag.riskColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(diag.patientName,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            )),
                        Text(diag.zone,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.textHint,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.bgSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Image lésion ─────────────────────
                const Text('Image de la lésion',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.bgSoft,
                    child: Image.network(
                      diag.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                              const SizedBox(height: 8),
                              const Text('Chargement…',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: AppColors.textHint,
                                  )),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: diag.riskColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: CustomPaint(
                                painter: _LesionSimPainter(diag.riskColor),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Image non disponible',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Score IA + ABCDE ─────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: diag.riskColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.analytics_rounded,
                            color: diag.riskColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Score IA : '
                          '${(diag.riskPercent * 100).toInt()}%'
                          ' — Risque ${diag.riskLabel}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: diag.riskColor,
                          ),
                        ),
                      ]),
                      if (diag.abcdeFlags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 8),
                        Text(
                          'Critères ABCDE détectés :',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: diag.riskColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: diag.abcdeFlags
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: diag.riskColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: diag.riskColor,
                                          size: 11,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(f,
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: diag.riskColor,
                                            )),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Row(children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.riskLow,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Aucun critère ABCDE préoccupant',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.riskLow,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Champ avis ───────────────────────
                const Text('Votre avis médical',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Décrivez votre diagnostic, '
                        'recommandations et conduite à tenir…',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.bgSoft,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Boutons ──────────────────────────
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.bgSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('Annuler',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              )),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        if (ctrl.text.trim().isNotEmpty) {
                          prov.submitOpinion(diag.id, ctrl.text.trim());
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7F77DD),
                              Color(0xFF534AB7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7F77DD).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('Soumettre l\'avis',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Accueil',
            active: true,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-dashboard'),
          ),
          _NavItem(
            icon: Icons.people_rounded,
            label: 'Patients',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-patients'),
          ),
          _NavItem(
            icon: Icons.calendar_month_rounded,
            label: 'Agenda',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-agenda'),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-profile'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widgets
// ══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.3,
              )),
        ]),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final int badge;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7F77DD) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: active ? Colors.white : AppColors.textHint, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textHint,
                  )),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.riskHigh,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$badge',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : Colors.white,
                        )),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final PatientAppointment appt;
  final DoctorDashboardProvider prov;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  const _AppointmentCard({
    required this.appt,
    required this.prov,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = appt.status == AppointmentStatus.pending;
    final statusColor = prov.statusColor(appt.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? AppColors.riskMedium.withOpacity(0.25)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          // Avatar patient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: appt.riskColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(appt.patientInitials,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: appt.riskColor,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt.patientName,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                Text(appt.reason,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          // Badge statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(prov.statusLabel(appt.status),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                )),
          ),
        ]),
        const SizedBox(height: 10),
        // Date + risque
        Row(children: [
          const Icon(Icons.access_time_rounded,
              size: 13, color: AppColors.textHint),
          const SizedBox(width: 5),
          Text(prov.formatDateTime(appt.dateTime),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppColors.textHint,
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: appt.riskColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Risque ${appt.riskLevel}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: appt.riskColor,
                )),
          ),
        ]),
        const SizedBox(height: 10),
        Row(
          children: [
            if (appt.patientPhone.isNotEmpty) ...[
              const Icon(Icons.phone_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  appt.patientPhone,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else
              const Spacer(),
            if (appt.patientVille.isNotEmpty) ...[
              const SizedBox(width: 8),
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  appt.patientVille,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        if (appt.patientEmail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 13, color: AppColors.textHint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  appt.patientEmail,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _ActionBtn(
              label: 'Voir Dossier',
              color: AppColors.textHint,
              onTap: () =>
                  context.push('/doctor-patient-detail/${appt.patientId}'),
            ),
          ),
          const SizedBox(width: 8),
          if (appt.status == AppointmentStatus.pending) ...[
            Expanded(
              child: _ActionBtn(
                label: 'Refuser',
                color: AppColors.riskHigh,
                onTap: onRefuse,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Accepter',
                color: AppColors.riskLow,
                onTap: onAccept,
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  final PatientDiagnostic diag;
  final DoctorDashboardProvider prov;
  final VoidCallback onGiveOpinion;

  const _DiagnosticCard({
    required this.diag,
    required this.prov,
    required this.onGiveOpinion,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = diag.status == DiagnosticStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              isPending ? diag.riskColor.withOpacity(0.25) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Miniature image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Image.network(
                  diag.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: diag.riskColor.withOpacity(0.12),
                    child: Center(
                      child: Text(diag.patientInitials,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: diag.riskColor,
                          )),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(diag.patientName,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
                  Text(diag.zone,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            // Badge risque IA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: diag.riskColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(diag.riskPercent * 100).toInt()}%'
                ' — ${diag.riskLabel}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: diag.riskColor,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded,
                size: 13, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(prov.formatTimeAgo(diag.date),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: AppColors.textHint,
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPending
                    ? AppColors.riskMedium.withOpacity(0.1)
                    : AppColors.riskLow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPending ? 'Avis requis' : 'Avis donné',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isPending ? AppColors.riskMedium : AppColors.riskLow,
                ),
              ),
            ),
          ]),
          // Avis existant
          if (diag.doctorOpinion != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.riskLow.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.riskLow.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.riskLow, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(diag.doctorOpinion!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        )),
                  ),
                ],
              ),
            ),
          ],
          // Boutons avis et dossier
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _ActionBtn(
                label: 'Voir Dossier',
                color: AppColors.textHint,
                onTap: () =>
                    context.push('/doctor-patient-detail/${diag.patientId}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _ActionBtn(
                label: isPending ? 'Donner mon avis' : 'Modifier mon avis',
                color: const Color(0xFF7F77DD),
                onTap: onGiveOpinion,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? color.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: active ? color : AppColors.textHint, size: 22),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? color : AppColors.textHint,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Painter lésion simulée ────────────────────────────────────
class _LesionSimPainter extends CustomPainter {
  final Color color;
  _LesionSimPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
        c, size.width * 0.35, Paint()..color = color.withOpacity(0.6));
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(c.dx - 12, c.dy - 6 + i * 7.0),
        Offset(c.dx + 12, c.dy - 6 + i * 7.0),
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ),
      ),
    );
  }
}
