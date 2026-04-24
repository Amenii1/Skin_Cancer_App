import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/dashboard/dashboard_provider.dart';
import 'features/camera/camera_intake_screen.dart';
import 'features/camera/camera_provider.dart';
import 'features/analysis/result_screen.dart';
import 'features/analysis/result_provider.dart';
import 'features/body_map/body_map_screen.dart';
import 'features/body_map/body_map_provider.dart';
import 'features/tracking/tracking_screen.dart';
import 'features/tracking/tracking_provider.dart';
import 'features/dermatologist/dermatologist_screen.dart';
import 'features/dermatologist/dermatologist_provider.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/profile_provider.dart';
import 'features/booking/booking_screen.dart';
import 'features/booking/booking_provider.dart';
import 'features/doctor/doctor_dashboard_screen.dart';
import 'features/doctor/doctor_dashboard_provider.dart';
import 'features/doctor/doctor_patients_provider.dart';
import 'features/doctor/doctor_agenda_provider.dart';
import 'features/doctor/doctor_patients_screen.dart';
import 'features/doctor/doctor_agenda_screen.dart';
import 'features/doctor/doctor_profile_screen.dart';
import 'features/doctor/doctor_patient_detail_screen.dart';
import 'features/doctor/doctor_patient_detail_provider.dart';
import 'features/medical_record/medical_record_provider.dart';
import 'features/medical_record/medical_record_screen.dart';
import 'features/notifications/patient_notifications_provider.dart';
import 'features/notifications/patient_notifications_screen.dart';
import 'features/admin/admin_provider.dart';
import 'features/admin/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const DermaScanApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
        path: '/',
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen())),
    GoRoute(
        path: '/onboarding',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: OnboardingScreen())),
    GoRoute(
        path: '/login',
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen())),
    GoRoute(
        path: '/register',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: RegisterScreen())),
    GoRoute(
        path: '/dashboard',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DashboardScreen())),
    GoRoute(
        path: '/camera',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: CameraIntakeScreen())),
    GoRoute(
        path: '/result',
        pageBuilder: (_, __) => const NoTransitionPage(child: ResultScreen())),
    GoRoute(
        path: '/bodymap',
        pageBuilder: (_, __) => const NoTransitionPage(child: BodyMapScreen())),
    GoRoute(
        path: '/tracking',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: TrackingScreen())),
    GoRoute(
        path: '/dermatologist',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DermatologistScreen())),
    GoRoute(
        path: '/profile',
        pageBuilder: (_, state) {
          final focusAppointments =
              state.uri.queryParameters['focus'] == 'appointments';
          return NoTransitionPage(
              child: ProfileScreen(focusAppointments: focusAppointments));
        }),
    GoRoute(
        path: '/booking',
        pageBuilder: (_, __) => const NoTransitionPage(child: BookingScreen())),
    GoRoute(
        path: '/medical-record',
        pageBuilder: (_, state) {
          final imageId = state.uri.queryParameters['imageId'];
          return NoTransitionPage(
              child: MedicalRecordScreen(highlightImageId: imageId));
        }),
    GoRoute(
        path: '/notifications',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: PatientNotificationsScreen())),
    GoRoute(
        path: '/doctor-dashboard',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DoctorDashboardScreen())),
    GoRoute(
        path: '/admin-dashboard',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AdminDashboardScreen())),
    GoRoute(
        path: '/doctor-patients',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DoctorPatientsScreen())),
    GoRoute(
        path: '/doctor-agenda',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DoctorAgendaScreen())),
    GoRoute(
        path: '/doctor-profile',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: DoctorProfileScreen())),
    GoRoute(
        path: '/doctor-patient-detail/:patientId',
        pageBuilder: (context, state) {
          final id = state.pathParameters['patientId']!;
          return NoTransitionPage(
              child: DoctorPatientDetailScreen(patientId: id));
        }),
  ],
);

class DermaScanApp extends StatelessWidget {
  const DermaScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => ResultProvider()),
        ChangeNotifierProvider(create: (_) => BodyMapProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => DermatologistProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => DoctorDashboardProvider()),
        ChangeNotifierProvider(create: (_) => DoctorPatientsProvider()),
        ChangeNotifierProvider(create: (_) => DoctorAgendaProvider()),
        ChangeNotifierProvider(create: (_) => DoctorPatientDetailProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
        ChangeNotifierProvider(create: (_) => PatientNotificationsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp.router(
        title: 'DermaScan AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [
          Locale('fr', 'FR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
