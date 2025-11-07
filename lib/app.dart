import 'package:flutter/material.dart';
import 'customer/customer_rooms.dart';
import 'beforeLogin/pre_customer_room.dart';
import 'moderator/moderator_dashboard.dart';
import 'admin/admin_dashboard.dart';
import 'owner/owner_dashboard.dart';
import 'shared_admin_moderator/manage_service.dart';
import 'profile_page.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/rbac_test_screen.dart';
import 'services/session.dart';
import 'services/rbac_service.dart';

// Global navigator key (kept inside app.dart as requested)
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class CamsApp extends StatefulWidget {
  const CamsApp({super.key});

  @override
  State<CamsApp> createState() => _CamsAppState();
}

class _CamsAppState extends State<CamsApp> {
  String? _initialRoute;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    print('DEBUG: Starting _determineInitialRoute');
    final hasSeenOnboarding = await Session.hasSeenOnboarding();
    final isLoggedIn = await Session.isLoggedIn();
    print('DEBUG: hasSeenOnboarding: $hasSeenOnboarding, isLoggedIn: $isLoggedIn');

    String initialRoute;
    if (!hasSeenOnboarding) {
      initialRoute = '/onboarding';
      print('DEBUG: Route set to onboarding');
    } else if (!isLoggedIn) {
      initialRoute = '/login';
      print('DEBUG: Route set to login');
    } else {
      // User is logged in, check RBAC
      final usergroup = await Session.getUserGroup();
      final uactivation = await Session.getUserActivation();
      print('DEBUG: usergroup: $usergroup, uactivation: $uactivation');
      
      if (usergroup == null || uactivation == null) {
        // Invalid session data, redirect to login
        await Session.clear();
        initialRoute = '/login';
        print('DEBUG: Invalid session, route set to login');
      } else if (!RBACService.isUserActive(uactivation)) {
        // User account is not active
        await Session.clear();
        initialRoute = '/login';
        print('DEBUG: User not active, route set to login');
      } else {
        // Use RBAC service to determine dashboard route
        initialRoute = RBACService.getDashboardRoute(usergroup);
        print('DEBUG: RBAC route: $initialRoute');
      }
    }

    print('DEBUG: Final initialRoute: $initialRoute');
    if (mounted) {
      setState(() {
        _initialRoute = initialRoute;
        _isLoading = false;
      });
      print('DEBUG: Loading set to false, initialRoute: $_initialRoute');
    }
  }

  String _getRouteForUserGroup(String usergroup) {
    switch (usergroup.toLowerCase()) {
      case 'admin':
        return '/admin';
      case 'moderator':
        return '/moderator';
      case 'owner':
        return '/owner';
      case 'customer':
        return '/home';
      default:
        return '/home';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF0077B6),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'CAMS',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0077B6),
          primary: const Color(0xFF0077B6),
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFE7F0FF),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: _initialRoute ?? '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/before-login': (context) => const CustomerRoomsNotLogin(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        // Centralized post-login redirect so routing happens in app.dart
        '/after-login': (context) => const _PostLoginRedirect(),
        '/home': (context) => const RoomsPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminDashboard(),
        '/moderator': (context) => const ModeratorDashboard(),
        '/owner': (context) => const OwnerDashboard(),
        '/customer': (context) => const RoomsPage(),
        '/manage-services': (context) => const ManageServicesPage(),
        '/rbac-test': (context) => const RBACTestScreen(),
      },
    );
  }
}

class _PostLoginRedirect extends StatefulWidget {
  const _PostLoginRedirect();

  @override
  State<_PostLoginRedirect> createState() => _PostLoginRedirectState();
}

class _PostLoginRedirectState extends State<_PostLoginRedirect> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    try {
      final usergroup = await Session.getUserGroup();
      final uactivation = await Session.getUserActivation();
      String target = '/login';
      // DEBUG
      // ignore: avoid_print
      print('DEBUG: _PostLoginRedirect -> usergroup="' + (usergroup?.toString() ?? 'null') + '", uactivation="' + (uactivation?.toString() ?? 'null') + '"');
      if (usergroup != null && uactivation != null && RBACService.isUserActive(uactivation)) {
        target = RBACService.getDashboardRoute(usergroup);
        // ignore: avoid_print
        print('DEBUG: _PostLoginRedirect -> computed target route: ' + target);
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, target, (r) => false);
    } catch (_) {
      // ignore: avoid_print
      print('DEBUG: _PostLoginRedirect -> exception; routing to /login');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0077B6),
        ),
      ),
    );
  }
}