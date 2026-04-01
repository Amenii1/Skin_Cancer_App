import 'package:flutter/material.dart';
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
import 'features/camera/camera_screen.dart';
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
    GoRoute(path: '/',
        pageBuilder: (_, __) => const NoTransitionPage(child: SplashScreen())),
    GoRoute(path: '/onboarding',
        pageBuilder: (_, __) => const NoTransitionPage(child: OnboardingScreen())),
    GoRoute(path: '/login',
        pageBuilder: (_, __) => const NoTransitionPage(child: LoginScreen())),
    GoRoute(path: '/register',
        pageBuilder: (_, __) => const NoTransitionPage(child: RegisterScreen())),
    GoRoute(path: '/dashboard',
        pageBuilder: (_, __) => const NoTransitionPage(child: DashboardScreen())),
    GoRoute(path: '/camera',
        pageBuilder: (_, __) => const NoTransitionPage(child: CameraScreen())),
    GoRoute(path: '/result',
        pageBuilder: (_, __) => const NoTransitionPage(child: ResultScreen())),
    GoRoute(path: '/bodymap',
        pageBuilder: (_, __) => const NoTransitionPage(child: BodyMapScreen())),
    GoRoute(path: '/tracking',
        pageBuilder: (_, __) => const NoTransitionPage(child: TrackingScreen())),
    GoRoute(path: '/dermatologist',
        pageBuilder: (_, __) => const NoTransitionPage(child: DermatologistScreen())),
    GoRoute(path: '/profile',
        pageBuilder: (_, __) => const NoTransitionPage(child: ProfileScreen())),
    GoRoute(path: '/booking',
        pageBuilder: (_, __) => const NoTransitionPage(child: BookingScreen())),
    GoRoute(path: '/doctor-dashboard',
        pageBuilder: (_, __) => const NoTransitionPage(child: DoctorDashboardScreen())),
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
      ],
      child: MaterialApp.router(
        title: 'DermaScan AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}