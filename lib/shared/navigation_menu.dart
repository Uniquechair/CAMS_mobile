import 'package:flutter/material.dart';

class DrawerMenuItem {
  final IconData icon;
  final String label;

  const DrawerMenuItem(this.icon, this.label);
}

enum UserRole { admin, moderator, customer, owner }

UserRole? userRoleFromString(String? role) {
  final normalized = role?.toLowerCase().trim() ?? '';
  if (normalized == 'admin' || normalized == 'administrator') {
    return UserRole.admin;
  }
  if (normalized == 'moderator') {
    return UserRole.moderator;
  }
  if (normalized == 'customer') {
    return UserRole.customer;
  }
  if (normalized == 'owner') {
    return UserRole.owner;
  }
  return null;
}

List<DrawerMenuItem> drawerMenuItemsForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return const [
        DrawerMenuItem(Icons.dashboard, 'Dashboard'),
        DrawerMenuItem(Icons.people, 'User Management'),
        DrawerMenuItem(Icons.apartment, 'Properties'),
        DrawerMenuItem(Icons.calendar_today, 'Bookings'),
        DrawerMenuItem(Icons.receipt_long, 'BooknPayLog'),
        DrawerMenuItem(Icons.history, 'AuditTrails'),
        DrawerMenuItem(Icons.trending_up, 'Finance'),
        DrawerMenuItem(Icons.person, 'Profile'),
      ];
    case UserRole.moderator:
      return const [
        DrawerMenuItem(Icons.dashboard, 'Dashboard'),
        DrawerMenuItem(Icons.people, 'User Management'),
        DrawerMenuItem(Icons.apartment, 'Properties'),
        DrawerMenuItem(Icons.calendar_today, 'Bookings'),
        DrawerMenuItem(Icons.receipt_long, 'BooknPayLog'),
        DrawerMenuItem(Icons.history, 'AuditTrails'),
        DrawerMenuItem(Icons.trending_up, 'Finance'),
        DrawerMenuItem(Icons.person, 'Profile'),
      ];
    case UserRole.customer:
      return const [
        DrawerMenuItem(Icons.dashboard, 'Rooms'),
        DrawerMenuItem(Icons.shopping_cart, 'Cart'),
        DrawerMenuItem(Icons.calendar_today, 'Bookings'),
        DrawerMenuItem(Icons.notifications, 'Notifications'),
        DrawerMenuItem(Icons.person, 'Profile'),
      ];
    case UserRole.owner:
      return const [
        DrawerMenuItem(Icons.dashboard, 'Dashboard'),
        DrawerMenuItem(Icons.people, 'Customer'),
        DrawerMenuItem(Icons.people, 'Moderator/Admin'),
        DrawerMenuItem(Icons.apartment, 'Properties'),
        DrawerMenuItem(Icons.calendar_today, 'Bookings'),
        DrawerMenuItem(Icons.receipt_long, 'BooknPayLog'),
        DrawerMenuItem(Icons.trending_up, 'Finance'),
        DrawerMenuItem(Icons.history, 'AuditTrails'),
        DrawerMenuItem(Icons.layers, 'Cluster'),
        DrawerMenuItem(Icons.person, 'Profile'),
      ];
  }
}

