import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'admin_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _userSearchCtrl = TextEditingController();
  final _appointmentDateCtrl = TextEditingController();
  final _appointmentPatientCtrl = TextEditingController();
  final _appointmentDoctorCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken;
      context.read<AdminProvider>().loadAll(token);
    });
  }

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    _appointmentDateCtrl.dispose();
    _appointmentPatientCtrl.dispose();
    _appointmentDoctorCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final token = context.read<AuthProvider>().accessToken;
    await context.read<AdminProvider>().refreshSection(token);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<AdminProvider>();
    final isWide = MediaQuery.of(context).size.width >= 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4F9), Color(0xFFF4F7FB), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 250,
                                child: _Sidebar(
                                  current: provider.section,
                                  onChanged: provider.setSection,
                                  onLogout: () async {
                                    await auth.logout();
                                    if (!mounted) return;
                                    context.go('/login');
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _MainContent(
                                  auth: auth,
                                  provider: provider,
                                  userSearchCtrl: _userSearchCtrl,
                                  appointmentDateCtrl: _appointmentDateCtrl,
                                  appointmentPatientCtrl: _appointmentPatientCtrl,
                                  appointmentDoctorCtrl: _appointmentDoctorCtrl,
                                ),
                              ),
                            ],
                          )
                        : _MainContent(
                            auth: auth,
                            provider: provider,
                            userSearchCtrl: _userSearchCtrl,
                            appointmentDateCtrl: _appointmentDateCtrl,
                            appointmentPatientCtrl: _appointmentPatientCtrl,
                            appointmentDoctorCtrl: _appointmentDoctorCtrl,
                            mobileSidebar: _MobileSectionBar(
                              current: provider.section,
                              onChanged: provider.setSection,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final AuthProvider auth;
  final AdminProvider provider;
  final TextEditingController userSearchCtrl;
  final TextEditingController appointmentDateCtrl;
  final TextEditingController appointmentPatientCtrl;
  final TextEditingController appointmentDoctorCtrl;
  final Widget? mobileSidebar;

  const _MainContent({
    required this.auth,
    required this.provider,
    required this.userSearchCtrl,
    required this.appointmentDateCtrl,
    required this.appointmentPatientCtrl,
    required this.appointmentDoctorCtrl,
    this.mobileSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroHeader(
          name: auth.currentUser?.fullName ?? 'Admin',
          onLogout: () async {
            await auth.logout();
            if (!context.mounted) return;
            context.go('/login');
          },
        ),
        if (mobileSidebar != null) ...[
          const SizedBox(height: 16),
          mobileSidebar!,
        ],
        if (provider.errorMessage != null) ...[
          const SizedBox(height: 16),
          _InfoBanner(
            icon: Icons.warning_amber_rounded,
            color: AppColors.riskHigh,
            text: provider.errorMessage!,
          ),
        ],
        const SizedBox(height: 18),
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _SectionView(
            auth: auth,
            provider: provider,
            userSearchCtrl: userSearchCtrl,
            appointmentDateCtrl: appointmentDateCtrl,
            appointmentPatientCtrl: appointmentPatientCtrl,
            appointmentDoctorCtrl: appointmentDoctorCtrl,
          ),
      ],
    );
  }
}

class _SectionView extends StatelessWidget {
  final AuthProvider auth;
  final AdminProvider provider;
  final TextEditingController userSearchCtrl;
  final TextEditingController appointmentDateCtrl;
  final TextEditingController appointmentPatientCtrl;
  final TextEditingController appointmentDoctorCtrl;

  const _SectionView({
    required this.auth,
    required this.provider,
    required this.userSearchCtrl,
    required this.appointmentDateCtrl,
    required this.appointmentPatientCtrl,
    required this.appointmentDoctorCtrl,
  });

  @override
  Widget build(BuildContext context) {
    switch (provider.section) {
      case AdminSection.overview:
        return _OverviewSection(provider: provider);
      case AdminSection.users:
        return _UsersSection(
          auth: auth,
          provider: provider,
          userSearchCtrl: userSearchCtrl,
        );
      case AdminSection.dermatologists:
        return _DermatologistsSection(provider: provider);
      case AdminSection.appointments:
        return _AppointmentsSection(
          auth: auth,
          provider: provider,
          dateCtrl: appointmentDateCtrl,
          patientCtrl: appointmentPatientCtrl,
          doctorCtrl: appointmentDoctorCtrl,
        );
      case AdminSection.analyses:
        return _AnalysesSection(provider: provider);
      case AdminSection.alerts:
        return _AlertsSection(provider: provider);
    }
  }
}

class _OverviewSection extends StatelessWidget {
  final AdminProvider provider;

  const _OverviewSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final overview = provider.overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StatCard(
              title: 'Patients',
              value: '${overview.patients}',
              icon: Icons.groups_rounded,
              color: const Color(0xFF0A7EA4),
            ),
            _StatCard(
              title: 'Dermatologues',
              value: '${overview.dermatologists}',
              icon: Icons.medical_services_rounded,
              color: const Color(0xFF0E9F6E),
            ),
            _StatCard(
              title: 'Analyses',
              value: '${overview.analyses}',
              icon: Icons.biotech_rounded,
              color: const Color(0xFFEF7D32),
            ),
            _StatCard(
              title: 'Rendez-vous',
              value: '${overview.appointments}',
              icon: Icons.event_note_rounded,
              color: const Color(0xFFE0528D),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ChartCard(
              title: 'Cancer vs non-cancer',
              subtitle: 'Repartition clinique des resultats',
              width: 420,
              child: _CaseDistributionChart(
                cancer: overview.cancerCases,
                nonCancer: overview.nonCancerCases,
              ),
            ),
            _ChartCard(
              title: 'Utilisation du systeme',
              subtitle: 'Analyses effectuees sur 7 jours',
              width: 520,
              child: _UsageLineChart(points: overview.usage),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _FeedCard(
              title: 'Cas suspects',
              items: overview.suspiciousCases
                  .map(
                    (item) => _FeedItemData(
                      title: item.patientName,
                      subtitle: item.result,
                      meta: item.confidence == null
                          ? item.createdAt
                          : 'Confidence ${(item.confidence! * 100).toStringAsFixed(0)}%',
                    ),
                  )
                  .toList(),
              accent: AppColors.riskHigh,
            ),
            _FeedCard(
              title: 'Evenements systeme',
              items: overview.recentEvents
                  .map(
                    (item) => _FeedItemData(
                      title: item.title,
                      subtitle: item.body,
                      meta: item.createdAt,
                    ),
                  )
                  .toList(),
              accent: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _UsersSection extends StatelessWidget {
  final AuthProvider auth;
  final AdminProvider provider;
  final TextEditingController userSearchCtrl;

  const _UsersSection({
    required this.auth,
    required this.provider,
    required this.userSearchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final token = auth.accessToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Gestion des utilisateurs',
                subtitle: 'Recherche, activation et suppression des comptes',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: userSearchCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher par nom ou email',
                        prefixIcon: Icon(Icons.search_rounded),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: token == null
                          ? null
                          : (value) => provider.setUserSearch(token, value),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: provider.userRoleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(value: 'patient', child: Text('Patients')),
                      DropdownMenuItem(value: 'doctor', child: Text('Dermatologues')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: token == null
                        ? null
                        : (value) => provider.setUserRoleFilter(
                              token,
                              value ?? 'all',
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...provider.users.map(
          (user) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UserCard(
              user: user,
              onToggleStatus: token == null
                  ? null
                  : () => provider.toggleUserStatus(token, user),
              onDelete: token == null
                  ? null
                  : () => provider.deleteUser(token, user.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _DermatologistsSection extends StatelessWidget {
  final AdminProvider provider;

  const _DermatologistsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Gestion des dermatologues',
          subtitle: 'Profils, disponibilites, avis et activite recente',
        ),
        const SizedBox(height: 16),
        ...provider.dermatologists.map(
          (doctor) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF0A7EA4).withOpacity(0.12),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF0A7EA4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${doctor.speciality} • ${doctor.city}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(
                        label: doctor.isActive ? 'Actif' : 'Inactif',
                        color: doctor.isActive
                            ? const Color(0xFF0E9F6E)
                            : AppColors.riskHigh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MiniMetric(label: 'Disponibilites', value: '${doctor.availabilityCount}'),
                      _MiniMetric(label: 'Avis', value: '${doctor.reviewsCount}'),
                      _MiniMetric(label: 'RDV', value: '${doctor.appointmentsCount}'),
                      _MiniMetric(
                        label: 'Note moyenne',
                        value: doctor.averageRating?.toStringAsFixed(1) ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Creneaux disponibles',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: doctor.availability.isEmpty
                        ? const [Text('Aucun creneau renseigne')]
                        : doctor.availability
                            .map(
                              (slot) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: slot.isReserved
                                      ? const Color(0xFFFFF4EC)
                                      : const Color(0xFFEFF9F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${slot.date}  ${_shortTime(slot.start)}-${_shortTime(slot.end)}',
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Avis recents',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...doctor.reviews.take(3).map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${review.diagnostic}${review.rating == null ? '' : ' • ${review.rating}/5'}\n${review.comment}',
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentsSection extends StatelessWidget {
  final AuthProvider auth;
  final AdminProvider provider;
  final TextEditingController dateCtrl;
  final TextEditingController patientCtrl;
  final TextEditingController doctorCtrl;

  const _AppointmentsSection({
    required this.auth,
    required this.provider,
    required this.dateCtrl,
    required this.patientCtrl,
    required this.doctorCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final token = auth.accessToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(
                title: 'Gestion des rendez-vous',
                subtitle: 'Filtres par date, patient ou dermatologue',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CompactField(
                    width: 160,
                    controller: dateCtrl,
                    label: 'Date YYYY-MM-DD',
                    icon: Icons.calendar_today_rounded,
                  ),
                  _CompactField(
                    width: 220,
                    controller: patientCtrl,
                    label: 'Patient',
                    icon: Icons.person_search_rounded,
                  ),
                  _CompactField(
                    width: 220,
                    controller: doctorCtrl,
                    label: 'Dermatologue',
                    icon: Icons.medical_information_rounded,
                  ),
                  FilledButton.icon(
                    onPressed: token == null
                        ? null
                        : () => provider.setAppointmentFilters(
                              token,
                              date: dateCtrl.text,
                              patient: patientCtrl.text,
                              doctor: doctorCtrl.text,
                            ),
                    icon: const Icon(Icons.filter_alt_rounded),
                    label: const Text('Filtrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...provider.appointments.map(
          (appointment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AppointmentCard(
              item: appointment,
              onDelete: token == null
                  ? null
                  : () => provider.deleteAppointment(token, appointment.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysesSection extends StatelessWidget {
  final AdminProvider provider;

  const _AnalysesSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          child: Row(
            children: [
              const Expanded(
                child: _SectionTitle(
                  title: 'Gestion des analyses',
                  subtitle: 'Prediction IA, confiance et details patient',
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: provider.analysisFilter,
                  decoration: const InputDecoration(
                    labelText: 'Prediction',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Toutes')),
                    DropdownMenuItem(value: 'malignant', child: Text('Maligne')),
                    DropdownMenuItem(value: 'benign', child: Text('Benigne')),
                    DropdownMenuItem(value: 'unknown', child: Text('Inconnue')),
                  ],
                  onChanged: token == null
                      ? null
                      : (value) =>
                          provider.setAnalysisFilter(token, value ?? 'all'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...provider.analyses.map(
          (analysis) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AnalysisCard(item: analysis),
          ),
        ),
      ],
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final AdminProvider provider;

  const _AlertsSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Alertes et notifications',
          subtitle: 'Cas suspects et evenements critiques du systeme',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _FeedCard(
              title: 'Alertes cancer suspect',
              items: provider.alerts
                  .map(
                    (item) => _FeedItemData(
                      title: item.patientName,
                      subtitle: item.result,
                      meta: item.createdAt,
                    ),
                  )
                  .toList(),
              accent: AppColors.riskHigh,
            ),
            _FeedCard(
              title: 'Evenements importants',
              items: provider.events
                  .map(
                    (item) => _FeedItemData(
                      title: item.title,
                      subtitle: item.body,
                      meta: item.kind,
                    ),
                  )
                  .toList(),
              accent: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final VoidCallback onLogout;

  const _HeroHeader({required this.name, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF073B4C), Color(0xFF0A7EA4), Color(0xFF16A3B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A7EA4).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Deconnexion'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Admin Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Vue unifiee pour superviser patients, dermatologues, analyses et rendez-vous.\nBonjour $name.',
            style: const TextStyle(
              color: Color(0xFFDFF7FF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final AdminSection current;
  final ValueChanged<AdminSection> onChanged;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.current,
    required this.onChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Navigation',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ...AdminSection.values.map(
            (section) => _SectionTile(
              section: section,
              selected: current == section,
              onTap: () => onChanged(section),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Se deconnecter'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _MobileSectionBar extends StatelessWidget {
  final AdminSection current;
  final ValueChanged<AdminSection> onChanged;

  const _MobileSectionBar({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AdminSection.values
              .map(
                (section) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_sectionLabel(section)),
                    selected: current == section,
                    onSelected: (_) => onChanged(section),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  const _SectionTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0A7EA4) : AppColors.textSecondary;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      selected: selected,
      selectedTileColor: const Color(0xFFE8F4F9),
      leading: Icon(_sectionIcon(section), color: color),
      title: Text(
        _sectionLabel(section),
        style: TextStyle(
          color: color,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(title, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double width;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CaseDistributionChart extends StatelessWidget {
  final int cancer;
  final int nonCancer;

  const _CaseDistributionChart({
    required this.cancer,
    required this.nonCancer,
  });

  @override
  Widget build(BuildContext context) {
    final total = (cancer + nonCancer).clamp(1, 1 << 30);
    return Row(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: CustomPaint(
            painter: _PiePainter(
              cancerFraction: cancer / total,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendTile(
                color: AppColors.riskHigh,
                label: 'Cancer / suspect',
                value: '$cancer',
              ),
              const SizedBox(height: 12),
              _LegendTile(
                color: const Color(0xFF0E9F6E),
                label: 'Non-cancer',
                value: '$nonCancer',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageLineChart extends StatelessWidget {
  final List<UsagePoint> points;

  const _UsageLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: CustomPaint(
        painter: _LineChartPainter(points),
        child: Padding(
          padding: const EdgeInsets.only(top: 160),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points
                .map(
                  (point) => Text(
                    point.date.length >= 10 ? point.date.substring(5) : point.date,
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final String title;
  final List<_FeedItemData> items;
  final Color accent;

  const _FeedCard({
    required this.title,
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text('Aucune donnee pour le moment.')
          else
            ...items.take(5).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(item.subtitle),
                              Text(
                                item.meta,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserItem user;
  final Future<bool> Function()? onToggleStatus;
  final Future<bool> Function()? onDelete;

  const _UserCard({
    required this.user,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0A7EA4).withOpacity(0.12),
                child: Text(
                  user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF0A7EA4)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(user.email, style: const TextStyle(color: AppColors.textSecondary)),
                    Text(user.subtitle, style: const TextStyle(color: AppColors.textHint)),
                  ],
                ),
              ),
              _StatusPill(
                label: user.isActive ? 'Actif' : 'Desactive',
                color: user.isActive ? const Color(0xFF0E9F6E) : AppColors.riskHigh,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Detail utilisateur'),
                      content: Text(
                        'Nom: ${user.name}\nEmail: ${user.email}\nRole: ${user.role}\nTelephone: ${user.phone.isEmpty ? '-' : user.phone}',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Voir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        user.isActive ? const Color(0xFFEF7D32) : const Color(0xFF0E9F6E),
                  ),
                  onPressed: onToggleStatus == null
                      ? null
                      : () async {
                          final ok = await onToggleStatus!.call();
                          if (!context.mounted) return;
                          _showSnack(
                            context,
                            ok
                                ? 'Statut utilisateur mis a jour.'
                                : 'Operation impossible.',
                          );
                        },
                  icon: Icon(user.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded),
                  label: Text(user.isActive ? 'Desactiver' : 'Activer'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onDelete == null
                    ? null
                    : () async {
                        final ok = await onDelete!.call();
                        if (!context.mounted) return;
                        _showSnack(
                          context,
                          ok ? 'Utilisateur supprime.' : 'Suppression impossible.',
                        );
                      },
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AdminAppointmentItem item;
  final Future<bool> Function()? onDelete;

  const _AppointmentCard({
    required this.item,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0A7EA4)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.patientName} avec ${item.doctorName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${item.doctorSpeciality} • ${item.date} • ${_shortTime(item.start)}-${_shortTime(item.end)}',
                ),
                const SizedBox(height: 6),
                _StatusPill(
                  label: item.status,
                  color: item.status == 'accepted'
                      ? const Color(0xFF0E9F6E)
                      : item.status == 'refused'
                          ? AppColors.riskHigh
                          : const Color(0xFFEF7D32),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onDelete == null
                ? null
                : () async {
                    final ok = await onDelete!.call();
                    if (!context.mounted) return;
                    _showSnack(
                      context,
                      ok ? 'Rendez-vous supprime.' : 'Suppression impossible.',
                    );
                  },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final AdminAnalysisItem item;

  const _AnalysisCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isSuspicious ? AppColors.riskHigh : const Color(0xFF0E9F6E);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.patientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusPill(label: item.prediction, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.patientEmail),
          const SizedBox(height: 8),
          Text('Resultat: ${item.result}'),
          Text('Zone: ${item.bodyZone}'),
          Text(
            item.confidence == null
                ? 'Confiance: -'
                : 'Confiance: ${(item.confidence! * 100).toStringAsFixed(1)}%',
          ),
          Text('Date: ${item.createdAt}'),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final double width;
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _CompactField({
    required this.width,
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendTile({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _FeedItemData {
  final String title;
  final String subtitle;
  final String meta;

  const _FeedItemData({
    required this.title,
    required this.subtitle,
    required this.meta,
  });
}

class _PiePainter extends CustomPainter {
  final double cancerFraction;

  _PiePainter({required this.cancerFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    final base = Paint()..color = const Color(0xFFE7F2F1);
    canvas.drawCircle(center, radius, base);

    final cancerPaint = Paint()..color = AppColors.riskHigh;
    final nonCancerPaint = Paint()..color = const Color(0xFF0E9F6E);

    final start = -1.5708;
    final sweepCancer = 6.2831 * cancerFraction;
    canvas.drawArc(rect, start, sweepCancer, true, cancerPaint);
    canvas.drawArc(rect, start + sweepCancer, 6.2831 - sweepCancer, true, nonCancerPaint);

    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.cancerFraction != cancerFraction;
}

class _LineChartPainter extends CustomPainter {
  final List<UsagePoint> points;

  _LineChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 8.0;
    const topPadding = 12.0;
    const chartHeight = 128.0;
    final bottom = topPadding + chartHeight;
    final width = size.width - leftPadding * 2;
    final maxCount = points.fold<int>(1, (max, item) => item.count > max ? item.count : max);

    final gridPaint = Paint()
      ..color = const Color(0xFFE6EEF5)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width - leftPadding, y), gridPaint);
    }

    if (points.isEmpty) return;

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final dx = leftPadding + (width / (points.length - 1).clamp(1, 999)) * i;
      final dy = bottom - (points[i].count / maxCount) * chartHeight;
      if (i == 0) {
        path.moveTo(dx, dy);
        fillPath.moveTo(dx, bottom);
        fillPath.lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
      canvas.drawCircle(
        Offset(dx, dy),
        4,
        Paint()..color = const Color(0xFF0A7EA4),
      );
    }
    fillPath
      ..lineTo(size.width - leftPadding, bottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x4D0A7EA4), Color(0x000A7EA4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0A7EA4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

String _sectionLabel(AdminSection section) {
  switch (section) {
    case AdminSection.overview:
      return 'Overview';
    case AdminSection.users:
      return 'Users';
    case AdminSection.dermatologists:
      return 'Dermatologists';
    case AdminSection.appointments:
      return 'Appointments';
    case AdminSection.analyses:
      return 'Analyses';
    case AdminSection.alerts:
      return 'Alerts';
  }
}

IconData _sectionIcon(AdminSection section) {
  switch (section) {
    case AdminSection.overview:
      return Icons.space_dashboard_rounded;
    case AdminSection.users:
      return Icons.groups_rounded;
    case AdminSection.dermatologists:
      return Icons.medical_services_rounded;
    case AdminSection.appointments:
      return Icons.calendar_month_rounded;
    case AdminSection.analyses:
      return Icons.biotech_rounded;
    case AdminSection.alerts:
      return Icons.notifications_active_rounded;
  }
}

void _showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

String _shortTime(String value) {
  if (value.length >= 5) return value.substring(0, 5);
  return value;
}
