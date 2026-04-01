import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import 'auth_provider.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) {
      // Redirection selon le rôle
      if (auth.isDermatologue) {
        context.go('/doctor-dashboard');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradStart, AppColors.gradEnd],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildFormCard(),
                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 20),
                      _buildDemoAccounts(),
                      const SizedBox(height: 28),
                      _buildSignUpLink(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.go('/onboarding'),
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
        ),
        const SizedBox(height: 28),
        Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.biotech_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text('DermaScan AI',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
        ]),
        const SizedBox(height: 20),
        const Text('Bon retour ! 👋',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary, height: 1.2,
            )),
        const SizedBox(height: 8),
        const Text(
          'Connectez-vous pour accéder à votre espace.',
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            color: AppColors.textSecondary, height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Card formulaire ───────────────────────────────────────
  Widget _buildFormCard() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(children: [
          if (auth.errorMessage != null) ...[
            _ErrorBanner(message: auth.errorMessage!),
            const SizedBox(height: 16),
          ],
          AuthTextField(
            label: 'Adresse email',
            hint: 'exemple@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
            onChanged: (_) => auth.clearError(),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            label: 'Mot de passe',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passCtrl,
            obscure: auth.obscurePassword,
            onChanged: (_) => auth.clearError(),
            suffix: IconButton(
              icon: Icon(
                auth.obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textHint, size: 20,
              ),
              onPressed: auth.togglePassword,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text('Mot de passe oublié ?',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  )),
            ),
          ),
          const SizedBox(height: 24),
          _LoginButton(
              onTap: _onLogin, isLoading: auth.isLoading),
          const SizedBox(height: 14),
          _BiometricButton(auth: auth),
        ]),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(children: [
      const Expanded(
          child: Divider(color: AppColors.border, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('comptes de démonstration',
            style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
            )),
      ),
      const Expanded(
          child: Divider(color: AppColors.border, thickness: 1)),
    ]);
  }

  // ── Comptes démo ──────────────────────────────────────────
  Widget _buildDemoAccounts() {
    return Row(children: [
      Expanded(
        child: _DemoCard(
          role: 'Patient',
          email: 'patient@demo.com',
          icon: Icons.person_rounded,
          color: AppColors.primary,
          onTap: () {
            _emailCtrl.text = 'patient@demo.com';
            _passCtrl.text = 'demo1234';
          },
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _DemoCard(
          role: 'Dermatologue',
          email: 'dermato@demo.com',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFF7F77DD),
          onTap: () {
            _emailCtrl.text = 'dermato@demo.com';
            _passCtrl.text = 'demo1234';
          },
        ),
      ),
    ]);
  }

  Widget _buildSignUpLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Pas encore de compte ? ',
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            color: AppColors.textSecondary,
          )),
      GestureDetector(
        onTap: () => context.go('/register'),
        child: const Text('S\'inscrire',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
      ),
    ]);
  }
}

// ── Widgets ───────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  const _LoginButton(
      {required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [AppColors.primaryLight, AppColors.primaryLight]
                : [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.30),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Se connecter',
                        style: AppFonts.labelBtn),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final AuthProvider auth;
  const _BiometricButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auth.toggleBiometric,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: auth.biometricEnabled
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: auth.biometricEnabled
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint_rounded,
                color: auth.biometricEnabled
                    ? AppColors.primary
                    : AppColors.textHint,
                size: 22),
            const SizedBox(width: 8),
            Text(
              auth.biometricEnabled
                  ? 'Biométrie activée'
                  : 'Connexion biométrique',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 14,
                fontWeight: FontWeight.w600,
                color: auth.biometricEnabled
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final String role;
  final String email;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _DemoCard({
    required this.role, required this.email,
    required this.icon, required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(role,
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w700, color: color,
              )),
          Text('Remplir auto',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 10,
                color: color.withOpacity(0.7),
              )),
        ]),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.riskHigh.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.riskHigh.withOpacity(0.25)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.riskHigh, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.riskHigh,
                fontWeight: FontWeight.w500,
              )),
        ),
      ]),
    );
  }
}