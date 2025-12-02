import 'package:flutter/material.dart';
import '../services/rbac_service.dart';
import '../services/session.dart';
import '../widgets/rbac_widgets.dart';

class RBACTestScreen extends StatefulWidget {
  const RBACTestScreen({super.key});

  @override
  State<RBACTestScreen> createState() => _RBACTestScreenState();
}

class _RBACTestScreenState extends State<RBACTestScreen> {
  String? _currentUserGroup;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserGroup();
  }

  Future<void> _loadCurrentUserGroup() async {
    final userGroup = await Session.getUserGroup();
    if (mounted) {
      setState(() {
        _currentUserGroup = userGroup;
      });
    }
  }

  Future<void> _switchRole(UserRole newRole) async {
    await Session.saveLogin(
      userid: 99,
      usergroup: newRole.toString().split('.').last,
      uactivation: 'active',
    );
    await _loadCurrentUserGroup();
    if (mounted) {
      final route = RBACService.getDashboardRoute(newRole.toString().split('.').last);
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RBAC Test Screen'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Info',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text('Role: ${_currentUserGroup ?? 'N/A'}'),
                    const SizedBox(height: 20),
                    Text(
                      'Switch Role (for testing):',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: UserRole.values.where((r) => r != UserRole.unknown).map((role) {
                        return ElevatedButton(
                          onPressed: () => _switchRole(role),
                          child: Text(RBACService.getRoleDisplayName(role.toString().split('.').last)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Permission-based Content:', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            _buildPermissionTestCard('View Dashboard', AppPermission.viewDashboard, const Text('You can view dashboards.')),
            _buildPermissionTestCard('Manage Users', AppPermission.manageUsers, const Text('You can manage user accounts.')),
            _buildPermissionTestCard('Manage Properties', AppPermission.manageProperties, const Text('You can manage properties.')),
            _buildPermissionTestCard('Manage Bookings', AppPermission.manageBookings, const Text('You can manage bookings.')),
            _buildPermissionTestCard('View Finance', AppPermission.viewFinance, const Text('You can view financial reports.')),
            _buildPermissionTestCard('View Audit Trails', AppPermission.viewAuditTrails, const Text('You can view audit trails.')),
            _buildPermissionTestCard('Access RBAC Test Screen', AppPermission.accessRBACTestScreen, const Text('You can access the RBAC test screen.')),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTestCard(String title, AppPermission permission, Widget content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RBACWidget(
              permission: permission,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.green.withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: content),
                  ],
                ),
              ),
              deniedWidget: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(child: Text('Access Denied')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
