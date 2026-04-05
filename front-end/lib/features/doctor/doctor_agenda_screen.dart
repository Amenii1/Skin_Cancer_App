import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class DoctorAgendaScreen extends StatefulWidget {
  const DoctorAgendaScreen({super.key});

  @override
  State<DoctorAgendaScreen> createState() => _DoctorAgendaScreenState();
}

class _DoctorAgendaScreenState extends State<DoctorAgendaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _selectedDayIndex = 0;

  final List<Map<String, dynamic>> _days = List.generate(7, (i) {
    final date = DateTime.now().add(Duration(days: i));
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const monthNames = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return {
      'date': date,
      'dayName': i == 0 ? 'Auj.' : dayNames[date.weekday - 1],
      'dayNum': date.day,
      'monthName': monthNames[date.month - 1],
    };
  });

  // Créneaux par jour
  final Map<int, List<Map<String, dynamic>>> _slots = {
    0: [
      {
        'time': '08h30',
        'patient': 'Thomas Bouchard',
        'initials': 'TB',
        'reason': 'Lésion suspecte — dos',
        'risk': 'Élevé',
        'riskColor': AppColors.riskHigh,
        'status': 'confirmed',
      },
      {
        'time': '10h00',
        'patient': 'Marie Dupont',
        'initials': 'MD',
        'reason': 'Suivi lésion bras gauche',
        'risk': 'Modéré',
        'riskColor': AppColors.riskMedium,
        'status': 'confirmed',
      },
      {
        'time': '11h30',
        'patient': null,
        'status': 'free',
      },
      {
        'time': '14h00',
        'patient': 'Lucas Martin',
        'initials': 'LM',
        'reason': 'Première consultation',
        'risk': 'Faible',
        'riskColor': AppColors.riskLow,
        'status': 'confirmed',
      },
      {
        'time': '15h30',
        'patient': null,
        'status': 'free',
      },
      {
        'time': '16h30',
        'patient': null,
        'status': 'free',
      },
    ],
    1: [
      {
        'time': '09h00',
        'patient': 'Sophie Bernard',
        'initials': 'SB',
        'reason': 'Contrôle annuel',
        'risk': 'Faible',
        'riskColor': AppColors.riskLow,
        'status': 'confirmed',
      },
      {
        'time': '10h30',
        'patient': null,
        'status': 'free',
      },
      {
        'time': '14h30',
        'patient': null,
        'status': 'free',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _currentSlots =>
      _slots[_selectedDayIndex] ??
      [
        {'time': '09h00', 'patient': null, 'status': 'free'},
        {'time': '10h30', 'patient': null, 'status': 'free'},
        {'time': '14h00', 'patient': null, 'status': 'free'},
        {'time': '15h30', 'patient': null, 'status': 'free'},
      ];

  int get _bookedCount =>
      _currentSlots.where((s) => s['status'] == 'confirmed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildDaySelector()),
            SliverToBoxAdapter(child: _buildDaySummary()),
            SliverToBoxAdapter(child: _buildSlotList()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
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
              Text('Mon agenda',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text('Gérez vos disponibilités',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        // Bouton bloquer créneau
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7F77DD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7F77DD).withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.block_rounded, color: Color(0xFF7F77DD), size: 16),
            SizedBox(width: 6),
            Text('Bloquer',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7F77DD),
                )),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        height: 72,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _days.length,
          itemBuilder: (_, i) {
            final day = _days[i];
            final isSelected = i == _selectedDayIndex;
            final hasAppts =
                (_slots[i]?.where((s) => s['status'] == 'confirmed').length ??
                        0) >
                    0;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                margin: EdgeInsets.only(right: i < _days.length - 1 ? 8 : 0),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF7F77DD) : AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isSelected ? const Color(0xFF7F77DD) : AppColors.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7F77DD).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day['dayName'],
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white70
                                  : AppColors.textHint,
                            )),
                        const SizedBox(height: 2),
                        Text('${day['dayNum']}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            )),
                      ],
                    ),
                    if (hasAppts && !isSelected)
                      Positioned(
                        top: 6,
                        right: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7F77DD),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaySummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        _AgendaStat(
          value: '$_bookedCount',
          label: 'RDV\nconfirmés',
          color: const Color(0xFF7F77DD),
        ),
        const SizedBox(width: 10),
        _AgendaStat(
          value: '${_currentSlots.where((s) => s['status'] == 'free').length}',
          label: 'Créneaux\nlibres',
          color: AppColors.riskLow,
        ),
        const SizedBox(width: 10),
        _AgendaStat(
          value: '${_currentSlots.length}',
          label: 'Total\ncréneaux',
          color: AppColors.primary,
        ),
      ]),
    );
  }

  Widget _buildSlotList() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Planning du jour',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const Spacer(),
            Text(
              '${_days[_selectedDayIndex]['dayName']} '
              '${_days[_selectedDayIndex]['dayNum']} '
              '${_days[_selectedDayIndex]['monthName']}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ..._currentSlots.map((slot) => _SlotCard(slot: slot)),
        ],
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
            active: true,
            color: const Color(0xFF7F77DD),
            onTap: () {},
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

class _SlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  const _SlotCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final isFree = slot['status'] == 'free';
    final riskColor = slot['riskColor'] as Color? ?? AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heure
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(slot['time'],
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHint,
                  )),
            ),
          ),
          // Ligne verticale
          Column(children: [
            Container(
              width: 2,
              height: 12,
              color: AppColors.border,
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFree ? AppColors.border : riskColor,
                border: Border.all(
                  color: isFree ? AppColors.border : riskColor.withOpacity(0.4),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: AppColors.border,
            ),
          ]),
          const SizedBox(width: 12),
          // Carte créneau
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFree ? AppColors.bgSoft : AppColors.bgWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFree
                      ? AppColors.border.withOpacity(0.5)
                      : riskColor.withOpacity(0.2),
                ),
                boxShadow: isFree
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
              ),
              child: isFree
                  ? Row(children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.textHint.withOpacity(0.5), size: 16),
                      const SizedBox(width: 8),
                      const Text('Créneau libre',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          )),
                    ])
                  : Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(slot['initials'],
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: riskColor,
                              )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot['patient'],
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                )),
                            Text(slot['reason'],
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(slot['risk'],
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: riskColor,
                            )),
                      ),
                    ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _AgendaStat({
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
