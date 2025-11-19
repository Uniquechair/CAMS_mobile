import 'package:flutter/material.dart';
import 'services/session.dart';
import 'services/rbac_service.dart' as rbac;
import 'api.dart' as api;
import 'app.dart';
import 'shared/navigation_menu.dart' as nav;
import 'shared/bottom_navigation_bar.dart';
import 'customer/customer_cart.dart';
import 'customer/customer_bookings.dart';
import 'customer/customer_notification.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _userRole;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userAddress;
  bool _isLoading = true;
  String? _errorMessage;
  String? _routeUserRole;
  int _selectedIndex = 3;

  // PayPal controller
  final TextEditingController _paypalController = TextEditingController();

  final Color _primaryBlue = const Color(0xFF0077B6);
  final Color _pageBg = const Color(0xFFE7F0FF);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textMuted = const Color(0xFF64748B);
  final BorderRadius _cardRadius = BorderRadius.circular(16);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_routeUserRole == null && args?['userRole'] != null) {
      _routeUserRole = args?['userRole'].toString();
    }
  }

  @override
  void dispose() {
    _paypalController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get user ID from session
      final userid = await Session.getUserId();
      if (userid == null) {
        throw Exception('User not logged in');
      }

      // Fetch user data from API
      final userData = await api.fetchUserData(userid);

      // Get user role from session
      final userGroup = await Session.getUserGroup();

      if (mounted) {
        setState(() {
          _userName = userData['username'] ?? widget.userName;
          _userEmail = userData['uemail'] ?? widget.userEmail;
          _userPhone = userData['uphoneno']?.toString();
          _userAddress = userData['ucountry'];
          _userRole = userGroup;
          _isLoading = false;

          // Prefill PayPal email if backend sends it
          _paypalController.text =
              (userData['paypal_email'] ?? '').toString();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _userName = widget.userName;
          _userEmail = widget.userEmail;
          _errorMessage = 'Could not load user data from server: $error';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _pageBg,
        title: const Text('Logout', style: TextStyle(color: Colors.black)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Session.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  // Dummy handler – plug in your backend API here
  Future<void> _updatePaypal() async {
    final paypalEmail = _paypalController.text.trim();

    if (paypalEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PayPal email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // TODO: call your backend API to save PayPal email

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PayPal information updated.'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
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

  String? get _effectiveRoleString {
    return (_userRole ?? _routeUserRole)?.toLowerCase();
  }

  nav.UserRole? get _userRoleEnum {
    return nav.userRoleFromString(_effectiveRoleString);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Fallback order: fetched data -> route args -> widget defaults
    final userName = _userName ?? args?['userName'] ?? widget.userName;
    final userEmail = _userEmail ?? args?['userEmail'] ?? widget.userEmail;
    final userRole = args?['userRole'] ?? _userRole ?? 'customer';
    final headerColor = _getHeaderColor(userRole);

    final roleLower = userRole.toString().toLowerCase();
    final bool canEditPaypal =
        roleLower == 'admin' ||
        roleLower == 'administrator' ||
        roleLower == 'moderator';
    final navRole = _userRoleEnum;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBg,
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
      endDrawer: navRole != null && navRole != nav.UserRole.customer ? MoreMenuDrawer(
        role: navRole,
        onItemSelected: _handleMenuSelection,
      ) : null,
      body: SafeArea(
        top: false,
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0077B6),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
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

                  // === Profile + Account card ===
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: _cardRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile header
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 46,
                                backgroundColor: headerColor,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: headerColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  rbac.RBACService.getRoleDisplayName(
                                      _userRole ?? userRole),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: headerColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: headerColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Settings page coming soon',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      backgroundColor: Color(0xFF468FAF),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.settings,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  "Edit Profile",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          "Account Information",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 20,
                          thickness: 1,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),

                        _infoRow(
                          icon: Icons.badge,
                          label: "Username",
                          value: userName,
                          color: headerColor,
                        ),
                        _infoRow(
                          icon: Icons.email_outlined,
                          label: "Email",
                          value: userEmail,
                          color: headerColor,
                        ),
                        _infoRow(
                          icon: Icons.verified_user,
                          label: "Account Status",
                          value: "Active",
                          color: headerColor,
                        ),
                        _infoRow(
                          icon: Icons.group,
                          label: "User Role",
                          value: _userRole != null
                              ? rbac.RBACService.getRoleDisplayName(_userRole!)
                              : userRole.toString().toUpperCase(),
                          color: headerColor,
                        ),
                        if (_userPhone != null && _userPhone!.isNotEmpty)
                          _infoRow(
                            icon: Icons.phone,
                            label: "Phone",
                            value: _userPhone!,
                            color: headerColor,
                          ),
                        if (_userAddress != null &&
                            _userAddress!.isNotEmpty)
                          _infoRow(
                            icon: Icons.location_on,
                            label: "Address",
                            value: _userAddress!,
                            color: headerColor,
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // === PayPal card (Admin / Moderator only) ===
                  if (canEditPaypal)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: _cardRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PayPal Email",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _paypalController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: "Enter your PayPal email",
                              hintStyle: TextStyle(color: _textMuted),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _primaryBlue,
                                  width: 1.6,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Payment Information",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "As an Admin or Moderator, you are required to "
                            "provide your PayPal account for receiving payments.",
                            style: TextStyle(
                              fontSize: 13,
                              color: _textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updatePaypal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryBlue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Update PayPal Information",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Logout button (full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 28,
                        ),
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
                  ),
                ],
              ),
            ),
      ),
      bottomNavigationBar: navRole != null ? SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: navRole,
      ) : null,
    );
  }

  void _handleBottomNavTap(int index) async {
    final role = _userRoleEnum;
    if (role == null) return;

    if (index == 4) {
      // More button - handled by SharedBottomNavigationBar to open drawer
      return;
    }

    if (index == 0) {
      // Dashboard/Home
      String route;
      switch (role) {
        case nav.UserRole.admin:
          route = '/admin';
          break;
        case nav.UserRole.moderator:
          route = '/moderator';
          break;
        case nav.UserRole.owner:
          route = '/owner';
          break;
        case nav.UserRole.customer:
          route = '/home';
          break;
      }
      final navigator = appNavigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(route, (route) => false);
      } else {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(route, (route) => false);
      }
      return;
    }

    if (index == 1) {
      // Properties/Cart
      if (role == nav.UserRole.customer) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerCart()),
        );
      } else {
        Navigator.of(context).pushNamed('/manage-services');
      }
      return;
    }

    if (index == 2) {
      // Bookings
      if (role == nav.UserRole.customer) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerBookings()),
        );
      } else {
        Navigator.of(context).pushNamed('/manage-booking');
      }
      return;
    }

    if (index == 3) {
      // Profile - already on this page
      if (_selectedIndex != 3) {
        setState(() => _selectedIndex = 3);
      }
    }
  }

  void _handleMenuSelection(String label) {
    final role = _userRoleEnum;
    if (role == null) return;

    switch (label) {
      case 'Dashboard':
        String route;
        switch (role) {
          case nav.UserRole.admin:
            route = '/admin';
            break;
          case nav.UserRole.moderator:
            route = '/moderator';
            break;
          case nav.UserRole.owner:
            route = '/owner';
            break;
          case nav.UserRole.customer:
            route = '/home';
            break;
        }
        final navigator = appNavigatorKey.currentState;
        if (navigator != null) {
          navigator.pushNamedAndRemoveUntil(route, (route) => false);
        } else {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(route, (route) => false);
        }
        break;
      case 'Profile':
        // Already on profile page
        break;
      case 'Properties':
      case 'PropertyListing':
        Navigator.of(context).pushNamed('/manage-services');
        break;
      case 'Reservation':
      case 'Bookings':
        Navigator.of(context).pushNamed('/manage-booking');
        break;
      case 'Rooms':
        Navigator.of(context).pushNamed('/home');
        break;
      case 'Cart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerCart()),
        );
        break;
      case 'Notifications':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CustomerNotifications()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to $label', style: const TextStyle(color: Colors.black)),
            backgroundColor: const Color(0xFF468FAF),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  // Small helper to keep account rows consistent & neat
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
