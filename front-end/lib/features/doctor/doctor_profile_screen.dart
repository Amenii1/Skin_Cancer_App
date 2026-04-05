import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _cabinetCtrl = TextEditingController();

  bool _editMode = false;
  bool _acceptingPatients = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final user = auth.currentUser;
      if (user != null) {
        _nameCtrl.text = user.fullName;
        _phoneCtrl.text = user.phone;
        _specialityCtrl.text = user.speciality ?? '';
        _cabinetCtrl.text = user.cabinetAddress ?? '';
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _specialityCtrl.dispose();
    _cabinetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, user)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInfoCard(user),
                  const SizedBox(height: 16),
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildPracticeCard(),
                  const SizedBox(height: 16),
                  _buildSecurityCard(),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context, auth),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7F77DD).withOpacity(0.15),
            AppColors.bgWhite,
          ],
        ),
      ),
      child: Column(children: [
        // Top row
        Row(children: [
          GestureDetector(
            onTap: () => context.go('/doctor-dashboard'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.bgWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('Mon profil médecin',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _editMode = !_editMode),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _editMode
                    ? AppColors.riskLow.withOpacity(0.12)
                    : const Color(0xFF7F77DD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _editMode
                      ? AppColors.riskLow.withOpacity(0.3)
                      : const Color(0xFF7F77DD).withOpacity(0.25),
                ),
              ),
              child: Text(
                _editMode ? 'Sauvegarder' : 'Modifier',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      _editMode ? AppColors.riskLow : const Color(0xFF7F77DD),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // Avatar médecin
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7F77DD), Color(0xFF534AB7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7F77DD).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.initials ?? 'DR',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Badge vérifié
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.riskLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Colors.white, size: 9),
                SizedBox(width: 3),
                Text('Vérifié',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),

        Text(
          user?.fullName ?? 'Dr. Médecin',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user?.speciality ?? 'Dermatologue',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (user?.rppsNumber != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF7F77DD).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'RPPS : ${user!.rppsNumber}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7F77DD),
              ),
            ),
          ),

        const SizedBox(height: 10),
        // Toggle accepte nouveaux patients
        GestureDetector(
          onTap: () => setState(() => _acceptingPatients = !_acceptingPatients),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _acceptingPatients
                  ? AppColors.riskLow.withOpacity(0.1)
                  : AppColors.riskHigh.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _acceptingPatients
                    ? AppColors.riskLow.withOpacity(0.3)
                    : AppColors.riskHigh.withOpacity(0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _acceptingPatients
                        ? AppColors.riskLow
                        : AppColors.riskHigh,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _acceptingPatients
                      ? 'Accepte de nouveaux patients'
                      : 'N\'accepte plus de patients',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _acceptingPatients
                        ? AppColors.riskLow
                        : AppColors.riskHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── Infos personnelles ────────────────────────────────────
  Widget _buildInfoCard(dynamic user) {
    return _DoctorSectionCard(
      title: 'Informations personnelles',
      icon: Icons.person_outline_rounded,
      child: Column(children: [
        _DoctorInfoRow(
          label: 'Nom complet',
          value: user?.fullName ?? '—',
          icon: Icons.badge_outlined,
          editMode: _editMode,
          controller: _nameCtrl,
        ),
        const SizedBox(height: 14),
        _DoctorInfoRow(
          label: 'Email professionnel',
          value: user?.email ?? '—',
          icon: Icons.email_outlined,
          editMode: false,
          controller: TextEditingController(text: user?.email ?? ''),
        ),
        const SizedBox(height: 14),
        _DoctorInfoRow(
          label: 'Téléphone',
          value: user?.phone ?? '—',
          icon: Icons.phone_outlined,
          editMode: _editMode,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
      ]),
    );
  }

  // ── Statistiques cabinet ──────────────────────────────────
  Widget _buildStatsCard() {
    return _DoctorSectionCard(
      title: 'Statistiques du cabinet',
      icon: Icons.bar_chart_rounded,
      child: Row(children: [
        _DoctorStat(
          value: '5',
          label: 'Patients\nactifs',
          color: const Color(0xFF7F77DD),
          icon: Icons.people_rounded,
        ),
        _DoctorStat(
          value: '3',
          label: 'Avis\ndonnés',
          color: AppColors.primary,
          icon: Icons.rate_review_rounded,
        ),
        _DoctorStat(
          value: '87%',
          label: 'Taux\nsatisfaction',
          color: AppColors.riskLow,
          icon: Icons.thumb_up_rounded,
        ),
      ]),
    );
  }

  // ── Informations cabinet ──────────────────────────────────
  Widget _buildPracticeCard() {
    return _DoctorSectionCard(
      title: 'Mon cabinet',
      icon: Icons.local_hospital_outlined,
      child: Column(children: [
        _DoctorInfoRow(
          label: 'Spécialité',
          value: _specialityCtrl.text.isEmpty
              ? 'Dermatologue'
              : _specialityCtrl.text,
          icon: Icons.medical_services_outlined,
          editMode: _editMode,
          controller: _specialityCtrl,
        ),
        const SizedBox(height: 14),
        _DoctorInfoRow(
          label: 'Adresse du cabinet',
          value:
              _cabinetCtrl.text.isEmpty ? 'Non renseignée' : _cabinetCtrl.text,
          icon: Icons.location_on_outlined,
          editMode: _editMode,
          controller: _cabinetCtrl,
        ),
        const SizedBox(height: 14),
        // Horaires simulés
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.access_time_rounded,
                    color: AppColors.primary, size: 15),
                SizedBox(width: 8),
                Text('Horaires d\'ouverture',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
              ]),
              const SizedBox(height: 8),
              ...[
                ('Lun — Ven', '08h30 — 18h00'),
                ('Samedi', '09h00 — 12h00'),
                ('Dimanche', 'Fermé'),
              ].map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      SizedBox(
                        width: 80,
                        child: Text(h.$1,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            )),
                      ),
                      Text(h.$2,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: h.$2 == 'Fermé'
                                ? AppColors.riskHigh
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          )),
                    ]),
                  )),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Sécurité ──────────────────────────────────────────────
  Widget _buildSecurityCard() {
    return _DoctorSectionCard(
      title: 'Sécurité & accès',
      icon: Icons.shield_outlined,
      child: Column(children: [
        // Badge HDS
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF7F77DD).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7F77DD).withOpacity(0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.health_and_safety_rounded,
                color: Color(0xFF7F77DD), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hébergement de Données de Santé',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7F77DD),
                      )),
                  Text(
                      'Certification HDS · Conformité RGPD '
                      '· Chiffrement AES-256',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        color: AppColors.textHint,
                      )),
                ],
              ),
            ),
            Icon(Icons.verified_rounded, color: Color(0xFF7F77DD), size: 18),
          ]),
        ),
        const SizedBox(height: 14),
        _DoctorToggleRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Nouvelles demandes de RDV',
          value: _notificationsEnabled,
          onToggle: () =>
              setState(() => _notificationsEnabled = !_notificationsEnabled),
          color: const Color(0xFF7F77DD),
        ),
        const Divider(color: AppColors.border, height: 20),
      ]),
    );
  }

  // ── Déconnexion ───────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return GestureDetector(
      onTap: () {
        auth.logout();
        context.go('/login');
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.riskHigh.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.riskHigh, size: 18),
            SizedBox(width: 8),
            Text('Se déconnecter',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.riskHigh,
                )),
          ],
        ),
      ),
    );
  }

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
          _BottomNavItem(
            icon: Icons.dashboard_rounded,
            label: 'Accueil',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-dashboard'),
          ),
          _BottomNavItem(
            icon: Icons.people_rounded,
            label: 'Patients',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-patients'),
          ),
          _BottomNavItem(
            icon: Icons.calendar_month_rounded,
            label: 'Agenda',
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-agenda'),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            active: true,
            color: const Color(0xFF7F77DD),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Widgets réutilisables
// ══════════════════════════════════════════════════════════════

class _DoctorSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DoctorSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7F77DD).withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF7F77DD), size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DoctorInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool editMode;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _DoctorInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.editMode,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF7F77DD).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF7F77DD), size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textHint,
                )),
            editMode
                ? TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF7F77DD)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF7F77DD), width: 1.5),
                      ),
                    ),
                  )
                : Text(value,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
          ],
        ),
      ),
    ]);
  }
}

class _DoctorToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;
  final Color color;

  const _DoctorToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onToggle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value ? color.withOpacity(0.1) : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: value ? color : AppColors.textHint, size: 17),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
            Text(subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textHint,
                )),
          ],
        ),
      ),
      GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 24,
          decoration: BoxDecoration(
            color: value ? color : AppColors.border,
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _DoctorStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _DoctorStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppColors.textSecondary,
                height: 1.2,
              )),
        ]),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _BottomNavItem({
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
