import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../features/shared_shell/presentation/main_shell.dart';
import '../../features/onboarding/presentation/language_selection_screen.dart';
import '../../features/onboarding/presentation/terms_screen.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/admin/presentation/admin_scans_screen.dart';
import '../../features/admin/presentation/admin_diseases_screen.dart';

import '../../features/disease_library/presentation/disease_library_screen.dart';
import '../../features/disease_library/presentation/disease_detail_screen.dart';
import '../../features/favourites/presentation/favourites_screen.dart';

import '../../features/admin/presentation/admin_settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/language', builder: (_, __) => const LanguageSelectionScreen()),
    GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
    GoRoute(path: '/result', builder: (_, state) => ResultScreen(scan: state.extra as Map<String, dynamic>?)),
    GoRoute(path: '/library', builder: (_, __) => const DiseaseLibraryScreen()),
    GoRoute(path: '/favourites', builder: (_, __) => const FavouritesScreen()),
    GoRoute(
      path: '/disease/:id',
      builder: (_, state) => DiseaseDetailScreen(
        diseaseId: int.parse(state.pathParameters['id']!),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/scan', builder: (_, __) => const ScanScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/history', builder: (_, __) => const HistoryScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())]),
      ],
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AdminShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/scans', builder: (_, __) => const AdminScansScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/diseases', builder: (_, __) => const AdminDiseasesScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/admin/settings', builder: (_, __) => const AdminSettingsScreen())]),
      ],
    ),
  ],
);

