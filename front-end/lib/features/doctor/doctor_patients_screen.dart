import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'doctor_patients_provider.dart';

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Données patients simulées
  final List<Map<String, dynamic>> _patients = [
    {
      'initials': 'TB',
      'name': 'Thomas Bouchard',
      'age': 34,
      'lastVisit': 'Il y a 1 jour',
      'lesions': 4,
      'risk': 'Élevé',
      'riskColor': AppColors.riskHigh,
      'status': 'Actif',
      'phone': '+33 6 12 34 56 78',
      'email': 'thomas.b@email.com',
    },
    {
      'initials': 'MD',
      'name': 'Marie Dupont',
      'age': 28,
      'lastVisit': 'Il y a 3 jours',
      'lesions': 2,
      'risk': 'Modéré',
      'riskColor': AppColors.riskMedium,
      'status': 'Actif',
      'phone': '+33 6 98 76 54 32',
      'email': 'marie.d@email.com',
    },
    {
      'initials': 'LM',
      'name': 'Lucas Martin',
      'age': 45,
      'lastVisit': 'Il y a 2 jours',
      'lesions': 1,
      'risk': 'Faible',
      'riskColor': AppColors.riskLow,
      'status': 'RDV confirmé',
      'phone': '+33 6 11 22 33 44',
      'email': 'lucas.m@email.com',
    },
    {
      'initials': 'SB',
      'name': 'Sophie Bernard',
      'age': 52,
      'lastVisit': 'Il y a 3 jours',
      'lesions': 3,
      'risk': 'Faible',
      'riskColor': AppColors.riskLow,
      'status': 'RDV confirmé',
      'phone': '+33 6 55 44 33 22',
      'email': 'sophie.b@email.com',
    },
    {
      'initials': 'PL',
      'name': 'Paul Leroy',
      'age': 61,
      'lastVisit': 'Il y a 5 jours',
      'lesions': 2,
      'risk': 'Faible',
      'riskColor': AppColors.riskLow,
      'status': 'Avis donné',
      'phone': '+33 6 77 88 99 00',
      'email': 'paul.l@email.com',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DoctorPatientsProvider>().fetchPatients(auth.accessToken);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PatientInfo> get _filtered {
    final patients = context.watch<DoctorPatientsProvider>().patients;
    if (_searchQuery.isEmpty) return patients;
    return patients
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorPatientsProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: prov.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7F77DD)))
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                _buildHeader(context),
                _buildSearchBar(),
                _buildStats(prov.patients),
                Expanded(child: _buildList()),
              ]),
            ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      color: AppColors.bgWhite,
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go('/doctor-dashboard'),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mes patients',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text('Gérez vos dossiers patients',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        // Filtre
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF7F77DD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7F77DD).withOpacity(0.3)),
          ),
          child: const Icon(Icons.filter_list_rounded,
              color: Color(0xFF7F77DD), size: 20),
        ),
      ]),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un patient…',
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textHint, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textHint, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.bgSoft,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF7F77DD), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildStats(List<PatientInfo> patients) {
    final high = patients.where((p) => p.riskLevel == 'Élevé').length;
    final medium = patients.where((p) => p.riskLevel == 'Modéré').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(children: [
        _MiniStat(
          value: '${patients.length}',
          label: 'Total',
          color: const Color(0xFF7F77DD),
        ),
        const SizedBox(width: 8),
        _MiniStat(
          value: '$high',
          label: 'Risque élevé',
          color: AppColors.riskHigh,
        ),
        const SizedBox(width: 8),
        _MiniStat(
          value: '$medium',
          label: 'Risque modéré',
          color: AppColors.riskMedium,
        ),
      ]),
    );
  }

  Widget _buildList() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 64, color: AppColors.textHint.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'Aucun patient trouvé',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final p = filtered[i];
        return _PatientCard(p: p);
      },
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
            active: true,
            color: const Color(0xFF7F77DD),
            onTap: () {},
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
            active: false,
            color: const Color(0xFF7F77DD),
            onTap: () => context.go('/doctor-profile'),
          ),
        ],
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final PatientInfo p;
  const _PatientCard({required this.p});

  @override
  Widget build(BuildContext context) {
    final riskColor = p.riskColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7F77DD).withOpacity(0.8),
                  const Color(0xFF534AB7).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(
              child: Text(p.initials,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
                Text(
                  '${p.lesionCount} lésion(s) · ${p.ville}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text('Dernière visite: ${p.lastVisit}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textHint,
                    )),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(p.riskLevel,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    )),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          if (p.phone.isNotEmpty)
            Expanded(
              child: _PatientActionBtn(
                icon: Icons.phone_outlined,
                label: p.phone,
                color: AppColors.riskLow,
              ),
            ),
          if (p.phone.isNotEmpty) const SizedBox(width: 10),
          const Expanded(
            child: _PatientActionBtn(
              icon: Icons.email_outlined,
              label: 'Envoyer email',
              color: Color(0xFF7F77DD),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _PatientActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PatientActionBtn({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
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
