import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../booking/booking_provider.dart';
import 'dermatologist_provider.dart';

class DermatologistScreen extends StatefulWidget {
  const DermatologistScreen({super.key});

  @override
  State<DermatologistScreen> createState() => _DermatologistScreenState();
}

class _DermatologistScreenState extends State<DermatologistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  final TextEditingController _searchCtrl = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final prov = context.read<DermatologistProvider>();
      final token = auth.accessToken;
      if (token != null && token.isNotEmpty) {
        prov.syncFromBackend(token);
        prov.getUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DermatologistProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(children: [
          _buildHeader(context, prov),
          _buildSearchBar(prov),
          if (prov.recommendationHint != null &&
              prov.recommendationHint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                ),
                child: Text(
                  prov.recommendationHint!,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // Bannière "Le plus proche disponible"
          if (prov.nearestAvailable != null && prov.userPosition != null)
            _buildNearestBanner(context, prov),
          _buildViewToggle(prov),
          Expanded(
            child: prov.listView
                ? _buildList(context, prov)
                : _buildMap(context, prov),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, DermatologistProvider prov) {
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
          onTap: () => context.go('/dashboard'),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dermatologues',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              Row(children: [
                Icon(
                  prov.locationLoading
                      ? Icons.location_searching_rounded
                      : prov.userPosition != null
                          ? Icons.location_on_rounded
                          : Icons.location_off_rounded,
                  size: 12,
                  color: prov.userPosition != null
                      ? AppColors.riskLow
                      : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    prov.locationLoading
                        ? 'Localisation en cours…'
                        : prov.userPosition != null
                            ? 'Position détectée — résultats triés par distance'
                            : prov.locationError ?? 'Position non disponible',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: prov.userPosition != null
                          ? AppColors.riskLow
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
        // Bouton relocaliser
        GestureDetector(
          onTap: prov.getUserLocation,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: prov.locationLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.my_location_rounded,
                    color: AppColors.primary, size: 20),
          ),
        ),
      ]),
    );
  }

  // ── Bannière le plus proche ───────────────────────────────
  Widget _buildNearestBanner(BuildContext context, DermatologistProvider prov) {
    final doc = prov.nearestAvailable!;
    return GestureDetector(
      onTap: () {
        prov.selectDoctor(doc);
        context.read<BookingProvider>().setDoctor(doc);
        context.go('/booking');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.all(14),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.near_me_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Le plus proche disponible',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    )),
                Text(doc.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
                Text(
                  '${prov.formatDistance(doc.distanceKm)} · ${doc.specialty.split('—').first.trim()}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('RDV',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                )),
          ),
        ]),
      ),
    );
  }

  // ── Barre de recherche ────────────────────────────────────
  Widget _buildSearchBar(DermatologistProvider prov) {
    return Container(
      color: AppColors.bgWhite,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: prov.search,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Nom, spécialité, adresse…',
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: AppColors.textHint,
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textHint, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppColors.textHint, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    prov.search('');
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Toggle vue ────────────────────────────────────────────
  Widget _buildViewToggle(DermatologistProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(children: [
        Text('${prov.filtered.length} résultat(s)',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            )),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            _ToggleBtn(
              icon: Icons.list_rounded,
              active: prov.listView,
              onTap: () {
                if (!prov.listView) prov.toggleView();
              },
            ),
            _ToggleBtn(
              icon: Icons.map_rounded,
              active: !prov.listView,
              onTap: () {
                if (prov.listView) prov.toggleView();
              },
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Vue liste ─────────────────────────────────────────────
  Widget _buildList(BuildContext context, DermatologistProvider prov) {
    final docs = prov.filtered;
    if (docs.isEmpty) {
      return const Center(
        child: Text('Aucun résultat',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              color: AppColors.textHint,
            )),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DoctorCard(
        doc: docs[i],
        isSelected: prov.selectedIndex == i,
        provider: prov,
        onTap: () => prov.select(i),
        onBook: () {
          context.read<BookingProvider>().setDoctor(docs[i]);
          context.go('/booking');
        },
      ),
    );
  }

  // ── Vue carte OpenStreetMap ───────────────────────────────
  Widget _buildMap(BuildContext context, DermatologistProvider prov) {
    final center = prov.userPosition != null
        ? LatLng(prov.userPosition!.latitude, prov.userPosition!.longitude)
        : const LatLng(48.8566, 2.3522);

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13,
          onTap: (_, __) => prov.select(-1),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.dermascan.app',
          ),
          // Marqueur utilisateur
          if (prov.userPosition != null)
            MarkerLayer(markers: [
              Marker(
                point: center,
                width: 44,
                height: 44,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_pin_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ]),
          // Marqueurs médecins
          MarkerLayer(
            markers: prov.filtered.asMap().entries.map((entry) {
              final i = entry.key;
              final doc = entry.value;
              final isSelected = prov.selectedIndex == i;
              final isNearest = prov.nearestAvailable?.id == doc.id;

              return Marker(
                point: LatLng(doc.lat, doc.lng),
                width: isSelected ? 170 : 130,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    prov.select(i);
                    _mapController.move(LatLng(doc.lat, doc.lng), 15);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : isNearest
                              ? AppColors.accent
                              : AppColors.bgWhite,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected
                                  ? AppColors.primary
                                  : AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNearest
                              ? Icons.near_me_rounded
                              : Icons.medical_services_rounded,
                          color: isSelected || isNearest
                              ? Colors.white
                              : AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isSelected
                                ? doc.name.split(' ').last
                                : prov.formatDistance(doc.distanceKm),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected || isNearest
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),

      // Card médecin sélectionné
      if (prov.selected != null)
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: _DoctorCard(
            doc: prov.selected!,
            isSelected: true,
            provider: prov,
            onTap: () {},
            onBook: () {
              context.read<BookingProvider>().setDoctor(prov.selected!);
              context.go('/booking');
            },
          ),
        ),

      // Bouton recentrer
      Positioned(
        top: 12,
        right: 12,
        child: GestureDetector(
          onTap: () {
            if (prov.userPosition != null) {
              _mapController.move(center, 13);
            }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgWhite,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 20),
          ),
        ),
      ),
    ]);
  }
}

// ── Card médecin ──────────────────────────────────────────────
class _DoctorCard extends StatelessWidget {
  final DermatologistModel doc;
  final bool isSelected;
  final DermatologistProvider provider;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const _DoctorCard({
    required this.doc,
    required this.isSelected,
    required this.provider,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final availColor = doc.available ? AppColors.riskLow : AppColors.riskMedium;
    final isNearest = provider.nearestAvailable?.id == doc.id;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isNearest
                ? AppColors.accent.withOpacity(0.5)
                : isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
            width: isNearest || isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          // Badge "Plus proche"
          if (isNearest && provider.userPosition != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Row(children: [
                Icon(Icons.near_me_rounded, color: AppColors.accent, size: 13),
                SizedBox(width: 6),
                Text('Le plus proche disponible',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    )),
              ]),
            ),
          ],
          Row(children: [
            // Avatar
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      )),
                  Text(doc.specialty,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      )),
                  const SizedBox(height: 4),
                  Row(children: [
                    ...List.generate(
                        5,
                        (i) => Icon(
                              i < doc.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: const Color(0xFFFFBD00),
                              size: 12,
                            )),
                    const SizedBox(width: 4),
                    Text('${doc.rating} (${doc.reviewCount})',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppColors.textHint,
                        )),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  provider.formatDistance(doc.distanceKm),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: availColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.availabilityLabel(doc.available),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: availColor,
                    ),
                  ),
                ),
              ],
            ),
          ]),

          // Détails si sélectionné
          if (isSelected) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.textHint, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(doc.address,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    )),
              ),
            ]),
            const SizedBox(height: 10),
            if (doc.availableSlots.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Prochains créneaux :',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    )),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: doc.availableSlots
                    .map((slot) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Text(slot,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              )),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 14),
            ],
            // Boutons FONCTIONNELS
            Row(children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.call_rounded,
                  label: 'Appeler',
                  color: AppColors.riskLow,
                  onTap: () => provider.callDoctor(doc),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.directions_rounded,
                  label: 'Itinéraire',
                  color: AppColors.primary,
                  onTap: () => provider.openDirections(doc),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.calendar_today_rounded,
                  label: 'RDV',
                  color: AppColors.accent,
                  onTap: onBook,
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              )),
        ]),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon,
            color: active ? Colors.white : AppColors.textHint, size: 18),
      ),
    );
  }
}
