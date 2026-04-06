import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ProfileProvider>();
      final auth = context.read<AuthProvider>();
      prov.syncFromBackend(auth.accessToken).then((_) {
        if (!mounted) return;
        _nameCtrl.text = prov.fullName;
        _emailCtrl.text = prov.email;
        _phoneCtrl.text = prov.phone;
      });
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate(
      BuildContext context, ProfileProvider prov) async {
    final now = DateTime.now();
    final initial =
        prov.birthDate ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5, now.month, now.day),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.bgWhite,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.bgWhite,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      prov.setBirthDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ProfileProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, prov)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileCard(prov),
                  const SizedBox(height: 16),
                  _buildStatsCard(prov),
                  const SizedBox(height: 16),
                  _buildAppointmentsCard(context, prov),
                  const SizedBox(height: 16),
                  _buildSecurityCard(prov),
                  const SizedBox(height: 16),
                  _buildDataCard(context),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, ProfileProvider prov) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradStart, AppColors.bgWhite],
        ),
      ),
      child: Column(children: [
        // Top row
        Row(children: [
          GestureDetector(
            onTap: () => context.go('/dashboard'),
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
              child: Text('Mon profil',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
            ),
          ),
          GestureDetector(
            onTap: prov.editMode
                ? () => prov.saveProfile(
                      name: _nameCtrl.text,
                      email: _emailCtrl.text,
                      phone: _phoneCtrl.text,
                    )
                : prov.toggleEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: prov.editMode
                    ? AppColors.riskLow.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: prov.editMode
                      ? AppColors.riskLow.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Text(
                prov.editMode ? 'Sauvegarder' : 'Modifier',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: prov.editMode ? AppColors.riskLow : AppColors.primary,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // Avatar
        Stack(alignment: Alignment.bottomRight, children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                prov.initials,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Badge patient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text('Patient',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ),
        ]),
        const SizedBox(height: 12),

        Text(prov.fullName,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 4),
        Text(prov.email,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.textHint,
            )),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Membre depuis ${prov.memberSince}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ),
      ]),
    );
  }

  // ── Infos personnelles ────────────────────────────────────
  Widget _buildProfileCard(ProfileProvider prov) {
    return _SectionCard(
      title: 'Informations personnelles',
      icon: Icons.person_outline_rounded,
      child: Column(children: [
        _InfoRow(
          label: 'Nom complet',
          value: prov.fullName,
          icon: Icons.badge_outlined,
          editMode: prov.editMode,
          controller: _nameCtrl,
        ),
        const SizedBox(height: 14),
        _InfoRow(
          label: 'Email',
          value: prov.email,
          icon: Icons.email_outlined,
          editMode: prov.editMode,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _InfoRow(
          label: 'Téléphone',
          value: prov.phone,
          icon: Icons.phone_outlined,
          editMode: prov.editMode,
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),

        // ── Date de naissance avec picker ──
        GestureDetector(
          onTap: () => _pickBirthDate(context, prov),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: prov.birthDate == null
                    ? AppColors.riskMedium.withOpacity(0.4)
                    : AppColors.border,
              ),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cake_outlined,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date de naissance',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppColors.textHint,
                        )),
                    Row(children: [
                      Text(
                        prov.birthDateFormatted,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: prov.birthDate == null
                              ? AppColors.textHint
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (prov.age != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${prov.age} ans',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
              Icon(
                prov.birthDate == null
                    ? Icons.add_circle_outline_rounded
                    : Icons.edit_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ]),
          ),
        ),
        if (prov.birthDate == null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.riskMedium.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.riskMedium.withOpacity(0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.riskMedium, size: 14),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Renseignez votre date de naissance pour un suivi personnalisé.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.riskMedium,
                  ),
                ),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        _InfoRow(
          label: 'Groupe sanguin',
          value: prov.bloodType,
          icon: Icons.bloodtype_outlined,
          editMode: false,
          controller: TextEditingController(text: prov.bloodType),
        ),
      ]),
    );
  }

  // ── Statistiques ──────────────────────────────────────────
  Widget _buildStatsCard(ProfileProvider prov) {
    return _SectionCard(
      title: 'Mes statistiques',
      icon: Icons.bar_chart_rounded,
      child: Row(children: [
        _StatItem(
          value: '${prov.totalScans}',
          label: 'Scans\neffectués',
          color: AppColors.primary,
          icon: Icons.camera_alt_rounded,
        ),
        _StatItem(
          value: '${prov.totalLesions}',
          label: 'Lésions\nsuivies',
          color: AppColors.riskMedium,
          icon: Icons.track_changes_rounded,
        ),
        _StatItem(
          value: '${prov.daysActive}',
          label: 'Jours\nactifs',
          color: AppColors.accent,
          icon: Icons.local_fire_department_rounded,
        ),
      ]),
    );
  }

  // ── Rendez-vous ───────────────────────────────────────────
  Widget _buildAppointmentsCard(BuildContext context, ProfileProvider prov) {
    return _SectionCard(
      title: 'Mes rendez-vous',
      icon: Icons.event_available_rounded,
      trailing: GestureDetector(
        onTap: () => context.go('/dermatologist'),
        child: const Text('+ Nouveau',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
      ),
      child: Column(children: [
        if (prov.upcomingAppointments.isEmpty)
          _buildEmptyAppointments(context)
        else
          ...prov.upcomingAppointments.map((appt) => _AppointmentTile(
                appointment: appt,
                prov: prov,
              )),
      ]),
    );
  }

  Widget _buildEmptyAppointments(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(children: [
          Icon(Icons.event_busy_rounded, color: AppColors.textHint, size: 32),
          SizedBox(height: 8),
          Text('Aucun rendez-vous à venir',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
          SizedBox(height: 4),
          Text('Prenez rendez-vous avec un dermatologue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppColors.textHint,
              )),
        ]),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => context.go('/dermatologist'),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Trouver un dermatologue',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ),
        ),
      ),
    ]);
  }

  // ── Sécurité ──────────────────────────────────────────────
  Widget _buildSecurityCard(ProfileProvider prov) {
    return _SectionCard(
      title: 'Sécurité & confidentialité',
      icon: Icons.shield_outlined,
      child: Column(children: [
        // Badge chiffrement
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.riskLow.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.riskLow.withOpacity(0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.lock_rounded, color: AppColors.riskLow, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Données chiffrées AES-256',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.riskLow,
                      )),
                  Text('Conformité RGPD · HDS',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.textHint,
                      )),
                ],
              ),
            ),
            Icon(Icons.verified_rounded, color: AppColors.riskLow, size: 20),
          ]),
        ),

        const Divider(color: AppColors.border, height: 20),
        _ToggleRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          subtitle: 'Rappels de suivi et RDV',
          value: prov.notificationsEnabled,
          onToggle: prov.toggleNotifications,
        ),
        const Divider(color: AppColors.border, height: 20),
        _ToggleRow(
          icon: Icons.security_rounded,
          label: 'Double authentification',
          subtitle: 'Code SMS à chaque connexion',
          value: prov.twoFactorEnabled,
          onToggle: prov.toggleTwoFactor,
        ),
        const Divider(color: AppColors.border, height: 20),
        _ToggleRow(
          icon: Icons.cloud_sync_rounded,
          label: 'Sauvegarde automatique',
          subtitle: 'Synchronisation chiffrée',
          value: prov.autoBackup,
          onToggle: prov.toggleAutoBackup,
        ),
      ]),
    );
  }

  // ── Données & RGPD ────────────────────────────────────────
  Widget _buildDataCard(BuildContext context) {
    return _SectionCard(
      title: 'Mes données',
      icon: Icons.folder_outlined,
      child: Column(children: [
        _DataRow(
          icon: Icons.download_rounded,
          label: 'Exporter mes données',
          subtitle: 'Format JSON chiffré',
          color: AppColors.primary,
          onTap: () {},
        ),
        const Divider(color: AppColors.border, height: 20),
        _DataRow(
          icon: Icons.share_rounded,
          label: 'Partager avec un médecin',
          subtitle: 'Rapport PDF sécurisé',
          color: AppColors.accent,
          onTap: () {},
        ),
        const Divider(color: AppColors.border, height: 20),
        _DataRow(
          icon: Icons.delete_outline_rounded,
          label: 'Supprimer mes données',
          subtitle: 'Action irréversible',
          color: AppColors.riskHigh,
          onTap: () => _showDeleteConfirm(context),
        ),
      ]),
    );
  }

  // ── Déconnexion ───────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<AuthProvider>().logout();
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

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer mes données',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront supprimées définitivement.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            )),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Supprimer',
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
}

// ══════════════════════════════════════════════════════════════
// Widgets réutilisables
// ══════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
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
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            if (trailing != null) ...[
              const Spacer(),
              trailing!,
            ],
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final ProfileProvider prov;

  const _AppointmentTile({
    required this.appointment,
    required this.prov,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment['status'] as String;
    final statusColor = prov.appointmentStatusColor(status);
    final statusLabel = prov.appointmentStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
        ),
      ),
      child: Row(children: [
        // Avatar médecin
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              appointment['doctor'].toString().split(' ').last[0],
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
              Text(appointment['doctor'].toString(),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              Text(appointment['date'].toString(),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textHint,
                  )),
              Text(appointment['address'].toString(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Badge statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(statusLabel,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              )),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool editMode;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _InfoRow({
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
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 16),
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
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 1.5),
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

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withOpacity(0.1) : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: value ? AppColors.primary : AppColors.textHint, size: 17),
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
            color: value ? AppColors.primary : AppColors.border,
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({
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

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DataRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
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
        const Icon(Icons.arrow_forward_ios_rounded,
            color: AppColors.textHint, size: 14),
      ]),
    );
  }
}
