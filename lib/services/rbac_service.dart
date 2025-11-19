import 'package:flutter/material.dart';

enum UserRole {
  customer,
  moderator,
  owner,
  admin,
  unknown,
}

enum AppPermission {
  viewDashboard,
  manageUsers,
  manageProperties,
  manageBookings,
  viewFinance,
  viewAuditTrails,
  accessRBACTestScreen,
}

class RBACService {
  // Role -> permissions
  static final Map<UserRole, Set<AppPermission>> _rolePermissions = {
    UserRole.customer: {
      AppPermission.viewDashboard,
    },
    UserRole.moderator: {
      AppPermission.viewDashboard,
      AppPermission.manageProperties,
      AppPermission.manageBookings,
    },
    UserRole.owner: {
      AppPermission.viewDashboard,
      AppPermission.manageProperties,
      AppPermission.manageBookings,
      AppPermission.viewFinance,
    },
    UserRole.admin: {
      AppPermission.viewDashboard,
      AppPermission.manageUsers,
      AppPermission.manageProperties,
      AppPermission.manageBookings,
      AppPermission.viewFinance,
      AppPermission.viewAuditTrails,
      AppPermission.accessRBACTestScreen,
    },
  };

  static UserRole _parseUserRole(String usergroup) {
    final r = usergroup.trim().toLowerCase();
    switch (r) {
      case 'customer':
        return UserRole.customer;
      case 'moderator':
        return UserRole.moderator;
      case 'owner':
        return UserRole.owner;
      case 'administrator':
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  static String getRoleDisplayName(String usergroup) {
    final role = _parseUserRole(usergroup);
    return role.toString().split('.').last;
  }

  static Color getRoleColor(String role) {
    switch (role.trim().toLowerCase()) {
      case 'admin':
        return Colors.redAccent;
      case 'owner':
        return Colors.orangeAccent;
      case 'moderator':
        return Colors.purpleAccent;
      case 'customer':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  static bool hasPermission(String usergroup, AppPermission permission) {
    final role = _parseUserRole(usergroup);
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  static String getDashboardRoute(String usergroup) {
    final role = _parseUserRole(usergroup);
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.moderator:
        return '/moderator';
      case UserRole.owner:
        return '/owner';
      case UserRole.customer:
        return '/home';
      case UserRole.unknown:
      default:
        return '/login';
    }
  }

  static bool canAccessRoute(String usergroup, String route) {
    final role = _parseUserRole(usergroup);
    switch (route) {
      case '/admin':
        return role == UserRole.admin;
      case '/moderator':
        return role == UserRole.admin || role == UserRole.moderator;
      case '/owner':
        return role == UserRole.admin || role == UserRole.owner;
      case '/home':
      case '/customer':
        return role == UserRole.admin ||
            role == UserRole.moderator ||
            role == UserRole.owner ||
            role == UserRole.customer;
      case '/rbac-test':
        return hasPermission(usergroup, AppPermission.accessRBACTestScreen);
      case '/login':
      case '/signup':
      case '/onboarding':
        return true;
      default:
        return false;
    }
  }

  static bool isUserActive(String uactivation) {
    final a = uactivation.trim().toLowerCase();
    return a == 'active' || a == 'activated' || a == 'enable' || a == 'enabled' || a == '1' || a == 'true';
  }

  // Business rules helpers
  static bool canAssignRole(String userRole, String targetRole) {
    switch (userRole.trim().toLowerCase()) {
      case 'owner':
        return targetRole.trim().toLowerCase() == 'admin' || targetRole.trim().toLowerCase() == 'moderator';
      case 'admin':
        return targetRole.trim().toLowerCase() == 'moderator';
      default:
        return false;
    }
  }

  static bool canManageUser(String userRole, String targetUserRole) {
    switch (userRole.trim().toLowerCase()) {
      case 'owner':
        return true;
      case 'admin':
        return targetUserRole.trim().toLowerCase() == 'moderator' || targetUserRole.trim().toLowerCase() == 'customer';
      case 'moderator':
        return targetUserRole.trim().toLowerCase() == 'customer';
      default:
        return false;
    }
  }
}
