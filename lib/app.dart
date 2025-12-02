import 'package:flutter/material.dart';
import 'customer/customer_rooms.dart';
import 'customer/customer_cart.dart';
import 'customer/customer_bookings.dart';
import 'customer/customer_notification.dart';
import 'beforeLogin/pre_customer_room.dart';
import 'moderator/moderator_dashboard.dart';
import 'moderator/moderator_notification.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_notification.dart';
import 'owner/owner_dashboard.dart';
import 'owner/owner_property_listing.dart';
import 'owner/owner_reservation.dart';
import 'owner/owner_manage_customer.dart';
import 'owner/owner_manage_moderatoradmin.dart';
import 'owner/owner_audit_trails.dart';
import 'owner/owner_book_and_pay.dart';
import 'owner/owner_cluster.dart';
import 'admin/admin_audit_trails.dart';
import 'admin/admin_book_and_pay.dart';
import 'moderator/moderator_audit_trails.dart';
import 'moderator/moderator_book_and_pay.dart';
import 'shared_admin_moderator/manage_service.dart';
import 'shared_admin_moderator/user_management.dart';
import 'shared_admin_moderator/manage_booking.dart';
// Export AppRole for use in navigation
export 'shared_admin_moderator/user_management.dart' show AppRole;
import 'profile_page.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/rbac_test_screen.dart';
import 'forget_password.dart';
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
        '/forget-password': (context) => const ForgotPasswordRequestPage(),
        // Centralized post-login redirect so routing happens in app.dart
        '/after-login': (context) => const _PostLoginRedirect(),
        '/home': (context) => const RoomsPage(),
        '/profile': (context) => const ProfilePage(),
        '/admin': (context) => const AdminDashboard(),
        '/moderator': (context) => const ModeratorDashboard(),
        '/owner': (context) => const OwnerDashboard(),
        '/customer': (context) => const RoomsPage(),
        '/manage-services': (context) => const ManageServicesPage(),
        '/user-management': (context) {
          // Get role from route arguments or determine from current user
          final args = ModalRoute.of(context)?.settings.arguments;
          AppRole role;
          if (args is AppRole) {
            role = args;
          } else {
            // Default based on route - will be set when navigating
            role = AppRole.admin;
          }
          return AdminUserManagementPage(viewerRole: role);
        },
        '/manage-booking': (context) => const AdminManageBooking(),
        // Customer routes
        '/customer-cart': (context) => const CustomerCart(),
        '/customer-bookings': (context) => const CustomerBookings(),
        '/customer-notifications': (context) => const CustomerNotifications(),
        // Admin routes
        '/admin-notifications': (context) => const AdminNotifications(),
        // Moderator routes
        '/moderator-notifications': (context) => const ModeratorNotifications(),
        // Owner routes
        '/owner-property-listing': (context) => const OwnerPropertyListingPage(),
        '/owner-reservation': (context) => const OwnerReservationPage(),
        '/owner-manage-customer': (context) => const OwnerManageCustomers(),
        '/owner-manage-moderatoradmin': (context) => const OwnerManageOperators(),
        '/owner-audit-trails': (context) => const OwnerAuditTrails(),
        '/owner-book-and-pay': (context) => const OwnerBooknPayLog(),
        '/owner-cluster': (context) => const OwnerClusterPage(),
        '/admin-audit-trails': (context) => const AdminAuditTrails(),
        '/admin-book-and-pay': (context) => const AdminBooknPayLog(),
        '/moderator-audit-trails': (context) => const ModeratorAuditTrails(),
        '/moderator-book-and-pay': (context) => const ModeratorBooknPayLog(),
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

// Centralized Navigation Helper
// All navigation should use these methods to ensure routes are managed in app.dart
class AppNavigator {
  // Push a named route
  static Future<T?>? pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  // Push a named route and remove all previous routes
  static Future<T?>? pushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  // Push a named route using the global navigator key
  static Future<T?>? pushNamedGlobal<T>(
    String routeName, {
    Object? arguments,
  }) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      return navigator.pushNamed<T>(
        routeName,
        arguments: arguments,
      );
    }
    return null;
  }

  // Push a named route and remove all previous routes using global navigator key
  static Future<T?>? pushNamedAndRemoveUntilGlobal<T>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    final navigator = appNavigatorKey.currentState;
    if (navigator != null) {
      return navigator.pushNamedAndRemoveUntil<T>(
        routeName,
        predicate ?? (route) => false,
        arguments: arguments,
      );
    }
    return null;
  }

  // Pop the current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  // Pop using root navigator
  static void popRoot(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Replace current route
  static Future<T?>? pushReplacementNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
}