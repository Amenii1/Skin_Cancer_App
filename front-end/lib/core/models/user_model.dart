enum UserRole { patient, dermatologue }

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final String? speciality;      // Dermatologue seulement
  final String? cabinetAddress;  // Dermatologue seulement
  final String? rppsNumber;      // Numéro RPPS Dermatologue
  final bool isVerified;         // Compte vérifié

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.speciality,
    this.cabinetAddress,
    this.rppsNumber,
    this.isVerified = false,
  });

  bool get isPatient => role == UserRole.patient;
  bool get isDermatologue => role == UserRole.dermatologue;

  String get roleLabel =>
      role == UserRole.patient ? 'Patient' : 'Dermatologue';

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? speciality,
    String? cabinetAddress,
    bool? isVerified,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      speciality: speciality ?? this.speciality,
      cabinetAddress: cabinetAddress ?? this.cabinetAddress,
      rppsNumber: rppsNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}