import 'package:flutter/material.dart';
import 'services/session.dart';
import 'services/rbac_service.dart';
import 'api.dart' as api;

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfilePage({
    super.key,
    this.userName = 'User',
    this.userEmail = 'user@example.com',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userRole;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userAddress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('ProfilePage: Starting to load user data...');

      // Get user ID from session
      final userid = await Session.getUserId();
      print('ProfilePage: User ID from session: $userid');
      
      if (userid == null) {
        print('ProfilePage: No user ID found in session');
        throw Exception('User not logged in');
      }

      // Fetch user data from API
      print('ProfilePage: Calling API to fetch user data for userid: $userid');
      final userData = await api.fetchUserData(userid);
      print('ProfilePage: API response received: $userData');
      
      // Get user role from session
      final userGroup = await Session.getUserGroup();
      print('ProfilePage: User group from session: $userGroup');

      if (mounted) {
        setState(() {
          _userName = userData['username'] ?? widget.userName;
          _userEmail = userData['uemail'] ?? widget.userEmail;  // Database uses 'uemail'
          _userPhone = userData['uphoneno']?.toString();  // Database uses 'uphoneno' (BIGINT)
          _userAddress = userData['ucountry'];  // Using ucountry as address (no address field in DB)
          _userRole = userGroup;
          _isLoading = false;
        });
        print('ProfilePage: State updated with fetched data');
        print('Username: $_userName');
        print('Email: $_userEmail');
        print('Phone: $_userPhone');
        print('Address: $_userAddress');
        print('Role: $_userRole');
      }
    } catch (error) {
      print('ProfilePage: Error loading user data: $error');
      if (mounted) {
        setState(() {
          // Fallback to widget values or session data
          _userName = widget.userName;
          _userEmail = widget.userEmail;
          _errorMessage = 'Could not load user data from server: $error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: const Text('Logout', style: TextStyle(color: Colors.black)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear session data
      await Session.clear();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  Color _getHeaderColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const Color(0xFF649EFF);
      case 'moderator':
        return const Color(0xFF78AAFF);
      case 'owner':
        return const Color(0xFF4188FF);
      case 'customer':
        return const Color(0xFF92BBFF);
      default:
        return const Color(0xFF92BBFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Try to get arguments from route (fallback for navigation with args)
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Use fetched data first, then args, then widget defaults
    final userName = _userName ?? args?['userName'] ?? widget.userName;
    final userEmail = _userEmail ?? args?['userEmail'] ?? widget.userEmail;
    final userRole = args?['userRole'] ?? _userRole ?? 'customer';
    final headerColor = _getHeaderColor(userRole);
    
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: headerColor,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0077B6),
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Error message display
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadUserData,
                      color: Colors.orange.shade700,
                      tooltip: 'Retry',
                    ),
                  ],
                ),
              ),
            // 🧑 Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: headerColor,
                    child: const Icon(Icons.person, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Navigate to settings page when implemented
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings page coming soon', style: TextStyle(color: Colors.black)),
                          backgroundColor: Color(0xFF468FAF),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ℹ️ Account Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  ListTile(
                    leading: Icon(Icons.badge, color: headerColor),
                    title: const Text("Username"),
                    subtitle: Text(userName),
                  ),
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: headerColor),
                    title: const Text("Email"),
                    subtitle: Text(userEmail),
                  ),
                  ListTile(
                    leading: Icon(Icons.verified_user, color: headerColor),
                    title: const Text("Account Status"),
                    subtitle: const Text("Active"),
                  ),
                  ListTile(
                    leading: Icon(Icons.group, color: headerColor),
                    title: const Text("User Role"),
                    subtitle: Text(
                      _userRole != null 
                        ? RBACService.getRoleDisplayName(_userRole!) 
                        : userRole.toString().toUpperCase(),
                    ),
                  ),
                  if (_userPhone != null && _userPhone!.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.phone, color: headerColor),
                      title: const Text("Phone"),
                      subtitle: Text(_userPhone!),
                    ),
                  if (_userAddress != null && _userAddress!.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.location_on, color: headerColor),
                      title: const Text("Address"),
                      subtitle: Text(_userAddress!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🚪 Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}
