import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../dermatologist/dermatologist_provider.dart';
import 'booking_provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<BookingProvider>().bindAccessToken(auth.accessToken);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();

    if (prov.isConfirmed) {
      return _ConfirmationScreen(prov: prov);
    }

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
                  if (prov.doctor != null) _buildDoctorCard(prov.doctor!),
                  const SizedBox(height: 20),
                  _buildDaySelector(prov),
                  const SizedBox(height: 20),
                  _buildSlotGrid(prov),
                  const SizedBox(height: 20),
                  _buildReasonForm(prov),
                  const SizedBox(height: 20),
                  _buildSummary(prov),
                  const SizedBox(height: 20),
                  _buildConfirmButton(context, prov),
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
  Widget _buildHeader(BuildContext context, BookingProvider prov) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: AppColors.bgWhite,
      child: Row(children: [
        GestureDetector(
          onTap: () => context.go('/dermatologist'),
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
              Text('Prendre rendez-vous',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text('Choisissez un créneau disponible',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textHint,
                  )),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Card médecin ──────────────────────────────────────────
  Widget _buildDoctorCard(DermatologistModel doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              doc.name.split(' ').last[0],
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
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
              Text(doc.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Text(doc.specialty,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(doc.address,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.textHint,
                      )),
                ),
              ]),
            ],
          ),
        ),
        // Note
        Column(children: [
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFBD00), size: 14),
            const SizedBox(width: 3),
            Text('${doc.rating}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
          ]),
          Text('${doc.reviewCount} avis',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                color: AppColors.textHint,
              )),
        ]),
      ]),
    );
  }

  // ── Sélecteur de jour ─────────────────────────────────────
  Widget _buildDaySelector(BookingProvider prov) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choisissez une date',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            )),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: prov.days.length,
            itemBuilder: (_, i) {
              final day = prov.days[i];
              final isSelected = i == prov.selectedDayIndex;
              return GestureDetector(
                onTap: () => prov.selectDay(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  margin:
                      EdgeInsets.only(right: i < prov.days.length - 1 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(day.dayLabel,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textHint,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        day.date.day.toString(),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(prov.selectedDay.dateLabel,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: AppColors.textHint,
            )),
      ],
    );
  }

  // ── Grille de créneaux ────────────────────────────────────
  Widget _buildSlotGrid(BookingProvider prov) {
    final slots = prov.selectedDay.slots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Text('Créneaux disponibles',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          Spacer(),
          // Légende
          _SlotLegend(
              color: AppColors.bgSoft,
              textColor: AppColors.textHint,
              label: 'Indispo'),
          SizedBox(width: 8),
          _SlotLegend(
              color: AppColors.bgWhite,
              textColor: AppColors.textPrimary,
              label: 'Libre'),
          SizedBox(width: 8),
          _SlotLegend(
              color: AppColors.primary,
              textColor: Colors.white,
              label: 'Choisi'),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final isSelected = slot.isSelected;
            final isAvailable = slot.isAvailable;
            return GestureDetector(
              onTap: () => prov.selectSlot(slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isAvailable
                          ? AppColors.bgWhite
                          : AppColors.bgSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isAvailable
                            ? AppColors.border
                            : AppColors.border.withOpacity(0.5),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  slot.label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isAvailable
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                    decoration:
                        !isAvailable ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Formulaire motif ──────────────────────────────────────
  Widget _buildReasonForm(BookingProvider prov) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Motif de consultation',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 12),
          // Boutons motifs rapides
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Lésion suspecte',
              'Suivi lésion',
              'Première consultation',
              'Avis dermatologique',
              'Autre',
            ].map((motif) {
              final isSelected = prov.reason == motif;
              return GestureDetector(
                onTap: () {
                  prov.setReason(motif);
                  _reasonCtrl.text = motif;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.bgSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.4)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(motif,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Champ notes
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            onChanged: prov.setNotes,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Notes supplémentaires (optionnel)…',
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
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Récapitulatif ─────────────────────────────────────────
  Widget _buildSummary(BookingProvider prov) {
    if (prov.selectedSlot == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.event_available_rounded,
                color: AppColors.primary, size: 16),
            SizedBox(width: 8),
            Text('Récapitulatif',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                )),
          ]),
          const SizedBox(height: 10),
          _SummaryRow(
            icon: Icons.medical_services_outlined,
            label: 'Médecin',
            value: prov.doctor?.name ?? '—',
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: prov.formatConfirmedDate(),
          ),
          if (prov.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            _SummaryRow(
              icon: Icons.notes_rounded,
              label: 'Motif',
              value: prov.reason,
            ),
          ],
        ],
      ),
    );
  }

  // ── Bouton confirmation ───────────────────────────────────
  Widget _buildConfirmButton(BuildContext context, BookingProvider prov) {
    return GestureDetector(
      onTap: prov.canConfirm && !prov.isLoading
          ? () => prov.confirmBooking()
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: prov.canConfirm
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: prov.canConfirm ? null : AppColors.border,
          borderRadius: BorderRadius.circular(16),
          boxShadow: prov.canConfirm
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: prov.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color:
                          prov.canConfirm ? Colors.white : AppColors.textHint,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      prov.canConfirm
                          ? 'Confirmer le rendez-vous'
                          : 'Choisissez un créneau et un motif',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            prov.canConfirm ? Colors.white : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Écran de confirmation ─────────────────────────────────────
class _ConfirmationScreen extends StatelessWidget {
  final BookingProvider prov;
  const _ConfirmationScreen({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône succès animée
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.riskLow.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.riskLow.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.riskLow, size: 52),
              ),
              const SizedBox(height: 28),
              const Text('Rendez-vous confirmé !',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 12),
              Text(
                'Votre rendez-vous avec ${prov.doctor?.name ?? 'le médecin'} a été réservé.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Détails RDV
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(children: [
                  _SummaryRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Médecin',
                    value: prov.doctor?.name ?? '—',
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: prov.formatConfirmedDate(),
                  ),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lieu',
                    value: prov.doctor?.address ?? '—',
                  ),
                  if (prov.reason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _SummaryRow(
                      icon: Icons.notes_rounded,
                      label: 'Motif',
                      value: prov.reason,
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 32),
              // Bouton retour dashboard
              GestureDetector(
                onTap: () {
                  prov.reset();
                  context.go('/dashboard');
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('Retour au tableau de bord',
                        style: AppFonts.labelBtn),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/dermatologist'),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bgWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('Voir d\'autres médecins',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets utilitaires ───────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.primary, size: 15),
      const SizedBox(width: 8),
      Text('$label : ',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          )),
      Expanded(
        child: Text(value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            )),
      ),
    ]);
  }
}

class _SlotLegend extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;
  const _SlotLegend({
    required this.color,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.border),
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 9,
            color: textColor,
          )),
    ]);
  }
}
