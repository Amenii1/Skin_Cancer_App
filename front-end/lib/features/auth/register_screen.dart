import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/user_model.dart';
import 'auth_provider.dart';
import 'widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // Champs dermatologue
  final _rppsCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _cabinetCtrl = TextEditingController();

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
    ).animate(CurvedAnimation(
        parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().reset();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _rppsCtrl.dispose();
    _specialityCtrl.dispose();
    _cabinetCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
      phone: _phoneCtrl.text.trim(),
      speciality: _specialityCtrl.text.trim().isEmpty
          ? null
          : _specialityCtrl.text.trim(),
      rppsNumber: _rppsCtrl.text.trim().isEmpty
          ? null
          : _rppsCtrl.text.trim(),
      cabinetAddress: _cabinetCtrl.text.trim().isEmpty
          ? null
          : _cabinetCtrl.text.trim(),
    );
    if (ok && mounted) {
      if (auth.isDermatologue) {
        context.go('/doctor-dashboard');
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                      const SizedBox(height: 24),
                      // Sélecteur de rôle
                      _buildRoleSelector(auth),
                      const SizedBox(height: 20),
                      _buildFormCard(auth),
                      const SizedBox(height: 28),
                      _buildLoginLink(),
                      const SizedBox(height: 36),
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
          onTap: () => context.go('/login'),
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
        const SizedBox(height: 24),
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
        const Text('Créer un compte 🩺',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary, height: 1.2,
            )),
        const SizedBox(height: 8),
        const Text(
          'Rejoignez DermaScan AI pour surveiller votre santé cutanée.',
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            color: AppColors.textSecondary, height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Sélecteur rôle ────────────────────────────────────────
  Widget _buildRoleSelector(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Je suis :',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _RoleCard(
              role: UserRole.patient,
              label: 'Patient',
              subtitle: 'Je surveille ma peau',
              icon: Icons.person_rounded,
              color: AppColors.primary,
              isSelected: auth.selectedRole == UserRole.patient,
              onTap: () => auth.setRole(UserRole.patient),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RoleCard(
              role: UserRole.dermatologue,
              label: 'Dermatologue',
              subtitle: 'Je suis médecin',
              icon: Icons.medical_services_rounded,
              color: const Color(0xFF7F77DD),
              isSelected:
                  auth.selectedRole == UserRole.dermatologue,
              onTap: () => auth.setRole(UserRole.dermatologue),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Card formulaire ───────────────────────────────────────
  Widget _buildFormCard(AuthProvider auth) {
    return Container(
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

        // Champs communs
        AuthTextField(
          label: 'Nom complet',
          hint: auth.selectedRole == UserRole.dermatologue
              ? 'Dr. Jean Dupont'
              : 'Jean Dupont',
          prefixIcon: Icons.person_outline_rounded,
          controller: _nameCtrl,
          onChanged: (_) => auth.clearError(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Adresse email',
          hint: 'exemple@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          controller: _emailCtrl,
          onChanged: (_) => auth.clearError(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Téléphone',
          hint: '+33 6 12 34 56 78',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          controller: _phoneCtrl,
          onChanged: (_) => auth.clearError(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Mot de passe',
          hint: '•••••••• (min. 8 caractères)',
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
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirmer le mot de passe',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          controller: _confirmCtrl,
          obscure: auth.obscureConfirm,
          onChanged: (_) => auth.clearError(),
          suffix: IconButton(
            icon: Icon(
              auth.obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textHint, size: 20,
            ),
            onPressed: auth.toggleConfirm,
          ),
        ),

        // Champs spécifiques dermatologue
        if (auth.selectedRole == UserRole.dermatologue) ...[
          const SizedBox(height: 20),
          _DermatoSection(
            rppsCtrl: _rppsCtrl,
            specialityCtrl: _specialityCtrl,
            cabinetCtrl: _cabinetCtrl,
            onChanged: () => auth.clearError(),
          ),
        ],

        const SizedBox(height: 20),
        _PasswordStrength(password: _passCtrl.text),
        const SizedBox(height: 18),
        _PolicyCheckbox(auth: auth),
        const SizedBox(height: 24),
        _RegisterButton(
            onTap: _onRegister,
            isLoading: auth.isLoading,
            role: auth.selectedRole),
        const SizedBox(height: 14),
        _SecurityBadge(),
      ]),
    );
  }

  Widget _buildLoginLink() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('Déjà un compte ? ',
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 14,
            color: AppColors.textSecondary,
          )),
      GestureDetector(
        onTap: () => context.go('/login'),
        child: const Text('Se connecter',
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
      ),
    ]);
  }
}

// ── Widgets register ──────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role, required this.label,
    required this.subtitle, required this.icon,
    required this.color, required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.08)
              : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withOpacity(0.5)
                : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.12)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : AppColors.bgSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isSelected ? color : AppColors.textHint,
                size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : AppColors.textPrimary,
              )),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11,
                color: isSelected
                    ? color.withOpacity(0.8)
                    : AppColors.textHint,
              )),
          if (isSelected) ...[
            const SizedBox(height: 6),
            Icon(Icons.check_circle_rounded,
                color: color, size: 16),
          ],
        ]),
      ),
    );
  }
}

class _DermatoSection extends StatelessWidget {
  final TextEditingController rppsCtrl;
  final TextEditingController specialityCtrl;
  final TextEditingController cabinetCtrl;
  final VoidCallback onChanged;

  const _DermatoSection({
    required this.rppsCtrl, required this.specialityCtrl,
    required this.cabinetCtrl, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF7F77DD).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF7F77DD).withOpacity(0.25)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFF7F77DD), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Informations professionnelles requises pour la vérification de votre compte.',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: Color(0xFF534AB7),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Numéro RPPS (11 chiffres)',
          hint: '10003456789',
          prefixIcon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          controller: rppsCtrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          label: 'Spécialité',
          hint: 'Dermatologue — Oncologie cutanée',
          prefixIcon: Icons.local_hospital_outlined,
          controller: specialityCtrl,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          label: 'Adresse du cabinet',
          hint: '12 Rue de la Paix, Paris 75001',
          prefixIcon: Icons.location_on_outlined,
          controller: cabinetCtrl,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  final String password;
  const _PasswordStrength({required this.password});

  int get _strength {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (password.contains(RegExp(r'[A-Z]'))) s++;
    if (password.contains(RegExp(r'[0-9]'))) s++;
    if (password.contains(RegExp(r'[!@#\$&*~]'))) s++;
    return s;
  }

  Color get _color {
    switch (_strength) {
      case 1: return AppColors.riskHigh;
      case 2: return AppColors.riskMedium;
      case 3: return AppColors.riskLow;
      case 4: return AppColors.accent;
      default: return AppColors.border;
    }
  }

  String get _label {
    switch (_strength) {
      case 1: return 'Faible';
      case 2: return 'Moyen';
      case 3: return 'Fort';
      case 4: return 'Très fort';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Expanded(
        child: Row(children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              height: 4,
              decoration: BoxDecoration(
                color: i < _strength ? _color : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        })),
      ),
      const SizedBox(width: 12),
      Text(_label,
          style: TextStyle(
            fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w600, color: _color,
          )),
    ]);
  }
}

class _PolicyCheckbox extends StatelessWidget {
  final AuthProvider auth;
  const _PolicyCheckbox({required this.auth});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auth.togglePolicy,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: auth.acceptPolicy
                ? AppColors.primary
                : AppColors.bgWhite,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: auth.acceptPolicy
                  ? AppColors.primary
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: auth.acceptPolicy
              ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                color: AppColors.textSecondary, height: 1.5,
              ),
              children: [
                TextSpan(text: 'J\'accepte la '),
                TextSpan(
                  text: 'politique de confidentialité',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' et les '),
                TextSpan(
                  text: 'conditions d\'utilisation',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' de DermaScan AI.'),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final UserRole role;
  const _RegisterButton({
    required this.onTap, required this.isLoading,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final color = role == UserRole.dermatologue
        ? const Color(0xFF7F77DD)
        : AppColors.primary;
    final color2 = role == UserRole.dermatologue
        ? const Color(0xFF534AB7)
        : AppColors.accent;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [color.withOpacity(0.6), color.withOpacity(0.6)]
                : [color, color2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.30),
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      role == UserRole.dermatologue
                          ? Icons.medical_services_rounded
                          : Icons.person_add_rounded,
                      color: Colors.white, size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role == UserRole.dermatologue
                          ? 'Créer mon compte médecin'
                          : 'Créer mon compte',
                      style: AppFonts.labelBtn,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined,
              color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Text('Données chiffrées · Conformité RGPD',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              )),
        ],
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