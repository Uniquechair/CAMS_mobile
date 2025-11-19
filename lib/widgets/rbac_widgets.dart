import 'package:flutter/material.dart';
import '../services/rbac_service.dart';
import '../services/session.dart';

class RBACWidget extends StatefulWidget {
  final AppPermission permission;
  final Widget child;
  final Widget? deniedWidget;

  const RBACWidget({
    super.key,
    required this.permission,
    required this.child,
    this.deniedWidget,
  });

  @override
  State<RBACWidget> createState() => _RBACWidgetState();
}

class _RBACWidgetState extends State<RBACWidget> {
  String? _userGroup;

  @override
  void initState() {
    super.initState();
    _loadUserGroup();
  }

  Future<void> _loadUserGroup() async {
    final userGroup = await Session.getUserGroup();
    if (mounted) {
      setState(() {
        _userGroup = userGroup;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroup == null) return const SizedBox.shrink();
    if (RBACService.hasPermission(_userGroup!, widget.permission)) {
      return widget.child;
    }
    return widget.deniedWidget ?? const SizedBox.shrink();
  }
}

class RoleBasedWidget extends StatefulWidget {
  final Map<UserRole, Widget> roleWidgets;
  final Widget? defaultWidget;

  const RoleBasedWidget({
    super.key,
    required this.roleWidgets,
    this.defaultWidget,
  });

  @override
  State<RoleBasedWidget> createState() => _RoleBasedWidgetState();
}

class _RoleBasedWidgetState extends State<RoleBasedWidget> {
  UserRole _currentUserRole = UserRole.unknown;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userGroupString = await Session.getUserGroup();
    if (mounted) {
      setState(() {
        _currentUserRole = userGroupString != null
            ? _parse(userGroupString)
            : UserRole.unknown;
        _isLoading = false;
      });
    }
  }

  UserRole _parse(String g) {
    switch (g.toLowerCase()) {
      case 'customer':
        return UserRole.customer;
      case 'moderator':
        return UserRole.moderator;
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0077B6),
        ),
      );
    }
    return widget.roleWidgets[_currentUserRole] ?? widget.defaultWidget ?? const SizedBox.shrink();
  }
}

class PermissionDeniedWidget extends StatelessWidget {
  final String message;
  const PermissionDeniedWidget({super.key, this.message = 'You do not have permission to view this content.'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
