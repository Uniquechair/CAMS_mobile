import 'package:flutter/material.dart';
import 'navigation_menu.dart';
import '../app.dart';

class SharedBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final UserRole role;

  const SharedBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.scaffoldKey,
    required this.role,
  });

  Color get _selectedColor {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF649EFF);
      case UserRole.moderator:
        return const Color(0xFF78AAFF);
      case UserRole.owner:
        return const Color(0xFF4188FF);
      case UserRole.customer:
        return const Color(0xFF92BBFF);
    }
  }

  List<BottomNavItem> get _navItems {
    switch (role) {
      case UserRole.admin:
      case UserRole.moderator:
      case UserRole.owner:
        return const [
          BottomNavItem(Icons.dashboard, 'Dashboard'),
          BottomNavItem(Icons.room_service, 'Properties'),
          BottomNavItem(Icons.calendar_today, 'Bookings'),
          BottomNavItem(Icons.person, 'Profile'),
          BottomNavItem(Icons.more_horiz, 'More'),
        ];
      case UserRole.customer:
        return const [
          BottomNavItem(Icons.home, 'Rooms'),
          BottomNavItem(Icons.shopping_cart, 'Cart'),
          BottomNavItem(Icons.calendar_today, 'Bookings'),
          BottomNavItem(Icons.person, 'Profile'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navItems
                .asMap()
                .entries
                .map((entry) => _buildBottomNavItem(
                      entry.value.icon,
                      entry.value.label,
                      entry.key,
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final isMoreButton = index == 4 && role != UserRole.customer;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (isMoreButton) {
            // More button - show drawer menu (only for non-customer roles)
            scaffoldKey?.currentState?.openEndDrawer();
          } else {
            onTap(index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? _selectedColor : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _selectedColor : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  const BottomNavItem(this.icon, this.label);
}

class MoreMenuDrawer extends StatelessWidget {
  final UserRole role;
  final Function(String) onItemSelected;
  final Future<void> Function()? onLogout;
  final String? currentPageLabel;

  const MoreMenuDrawer({
    super.key,
    required this.role,
    required this.onItemSelected,
    this.onLogout,
    this.currentPageLabel,
  });

  String get _headerTitle {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.owner:
        return 'Owner';
      case UserRole.customer:
        return 'Customer';
    }
  }

  List<Color> get _gradientColors {
    switch (role) {
      case UserRole.admin:
        return const [Color(0xFF6366F1), Color(0xFF649EFF)];
      case UserRole.moderator:
        return const [Color(0xFF6366F1), Color(0xFF78AAFF)];
      case UserRole.owner:
        return const [Color(0xFF6366F1), Color(0xFF4188FF)];
      case UserRole.customer:
        return const [Color(0xFF6366F1), Color(0xFF92BBFF)];
    }
  }

  Color get _borderColor {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFF649EFF);
      case UserRole.moderator:
        return const Color(0xFF78AAFF);
      case UserRole.owner:
        return const Color(0xFF4188FF);
      case UserRole.customer:
        return const Color(0xFF92BBFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = drawerMenuItemsForRole(role);

    return Drawer(
      child: Container(
        color: const Color(0xFF1E293B),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _gradientColors),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.supervised_user_circle, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _headerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _buildDrawerItem(items[i], isSelected: currentPageLabel != null && items[i].label == currentPageLabel),
                ],
              ),
            ),
            if (onLogout != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop(); // close drawer first
                    await onLogout?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(DrawerMenuItem item, {required bool isSelected}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _borderColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(item.icon, color: Colors.white, size: 24),
        title: Text(
          item.label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => onItemSelected(item.label),
      ),
    );
  }
}

