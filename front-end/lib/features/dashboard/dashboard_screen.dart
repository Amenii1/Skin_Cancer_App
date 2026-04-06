import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';
import 'widgets/risk_summary_card.dart';
import 'widgets/body_map_widget.dart';
import 'widgets/reminder_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DashboardProvider>().syncFromBackend(auth.accessToken);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                  child: _buildAppBar(context, prov)),
              // Bouton CTA Scanner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildCTAButton(context),
                ),
              ),
              // Actions rapides
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildQuickActions(context),
                ),
              ),
              // Contenu scrollable
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const RiskSummaryCard(),
                    const SizedBox(height: 16),
                    const BodyMapWidget(),
                    const SizedBox(height: 16),
                    const ReminderCard(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }

  // ── App Bar ───────────────────────────────────────────────
  Widget _buildAppBar(
      BuildContext context, DashboardProvider prov) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Text('T',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 18,
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
              Text(
                'Bonjour, ${prov.userName} 👋',
                style: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text('Tableau de bord santé',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
        // Notification
        Stack(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.textSecondary, size: 20),
          ),
          Positioned(
            top: 8, right: 8,
            child: Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.riskHigh,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── CTA Scanner ───────────────────────────────────────────
  Widget _buildCTAButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/camera'),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 16),
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analyser une nouvelle lésion',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                Text('Scan IA en quelques secondes',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 11,
                      color: Colors.white70,
                    )),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white70, size: 16),
          const SizedBox(width: 16),
        ]),
      ),
    );
  }

  // ── Actions rapides ───────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Column(children: [
      // Ligne 1 : Dermatologue + Corps
      Row(children: [
        Expanded(
          child: _QuickBtn(
            icon: Icons.folder_shared_rounded,
            label: 'Dossier\nmédical',
            color: AppColors.primary,
            onTap: () => context.go('/medical-record'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickBtn(
            icon: Icons.accessibility_new_rounded,
            label: 'Carte\ncorporelle',
            color: AppColors.accent,
            onTap: () => context.go('/bodymap'),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // Bannière Mes RDV
      GestureDetector(
        onTap: () => context.go('/dermatologist'),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            const SizedBox(width: 16),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event_available_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mes rendez-vous',
                      style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Text('Voir et gérer vos RDV',
                      style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 11,
                        color: AppColors.textHint,
                      )),
                ],
              ),
            ),
            // Badge RDV en attente
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.riskMedium.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('1 à venir',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.riskMedium,
                  )),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 16),
          ]),
        ),
      ),
    ]);
  }

  // ── Bottom Navigation ─────────────────────────────────────
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
            onTap: () => context.go('/dashboard'),
          ),
          _NavItem(
            icon: Icons.accessibility_new_rounded,
            label: 'Corps',
            active: false,
            onTap: () => context.go('/bodymap'),
          ),
          const SizedBox(width: 60),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'Suivi',
            active: false,
            onTap: () => context.go('/tracking'),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            active: false,
            onTap: () => context.go('/profile'),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/camera'),
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_a_photo_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }
}

// ── Quick Button ──────────────────────────────────────────────
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color, height: 1.3,
                )),
          ),
        ]),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon, required this.label,
    required this.active, required this.onTap,
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
                color: active
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: active
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: 22),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 10,
                  fontWeight: active
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: active
                      ? AppColors.primary
                      : AppColors.textHint,
                )),
          ],
        ),
      ),
    );
  }
}
