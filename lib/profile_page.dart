import 'dart:ui'; // For ImageFilter (blur)
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
import 'owner/owner_reservation.dart';
import 'owner/owner_property_listing.dart';
import 'shared_admin_moderator/user_management.dart';

enum _PasswordStrength { none, weak, medium, strong }

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfilePage({
    super.key,
    this.userName = 'User',
    this.userEmail = '',
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
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

  // Store full user data for updates
  Map<String, dynamic>? _fullUserData;

  String? _storedPassword;

  // PayPal controllers
  final TextEditingController _paypalController = TextEditingController();

  // Password controllers used in dialog
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Edit-profile dialog controllers
  final TextEditingController _editUsernameController =
      TextEditingController();
  final TextEditingController _editPhoneController = TextEditingController();

  // Shake animation for invalid input (dialog)
  late AnimationController _shakeController;
  late Animation<Offset> _shakeAnimation;

  // Password visibility (dialog)
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Password strength
  _PasswordStrength _passwordStrength = _PasswordStrength.none;

  // Saving state inside dialog (for loading spinner)
  bool _isSavingDialog = false;

  final Color _primaryBlue = const Color(0xFF0077B6);
  final Color _pageBg = const Color(0xFFE7F0FF);
  final Color _textDark = const Color(0xFF1E293B);
  final Color _textMuted = const Color(0xFF64748B);
  final BorderRadius _cardRadius = BorderRadius.circular(16);

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.03, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.03, 0), end: const Offset(0.03, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.03, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_routeUserRole == null && args?['userRole'] != null) {
      _routeUserRole = args?['userRole'].toString();
    }
  }

  @override
  void dispose() {
    _paypalController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _editUsernameController.dispose();
    _editPhoneController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildBaseUpdatePayload(int userid) {
    final payload = {
      'userid': userid,
      'username': _fullUserData?['username'] ?? _userName ?? '',
      'ufirstname':
          _fullUserData?['ufirstname'] ?? _fullUserData?['firstname'] ?? '',
      'ulastname':
          _fullUserData?['ulastname'] ?? _fullUserData?['lastname'] ?? '',
      'udob': _fullUserData?['udob'] ?? _fullUserData?['dob'] ?? null,
      'utitle': _fullUserData?['utitle'] ?? _fullUserData?['title'] ?? null,
      'ugender':
          _fullUserData?['ugender'] ?? _fullUserData?['gender'] ?? null,
      'uemail': _fullUserData?['uemail'] ?? _userEmail ?? '',
      'uphoneno': _fullUserData?['uphoneno'] ?? _userPhone ?? '',
      'ucountry': _fullUserData?['ucountry'] ?? _userAddress ?? '',
      'uzipcode':
          _fullUserData?['uzipcode'] ?? _fullUserData?['zipcode'] ?? null,
    };

    payload.removeWhere((key, value) {
      if (value == null) return true;
      if (value is String) {
        return value.trim().isEmpty;
      }
      return false;
    });

    final passwordValue = (_storedPassword ?? '').trim();
    if (passwordValue.isNotEmpty) {
      payload['password'] = passwordValue;
    }

    return payload;
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userid = await Session.getUserId();
      if (userid == null) {
        throw Exception('User not logged in');
      }

      final userData = await api.fetchUserData(userid);

      _fullUserData = userData;

      final userGroup = await Session.getUserGroup();

      if (mounted) {
        setState(() {
          _userName = userData['username'] ?? widget.userName;
          _userEmail = userData['uemail'] ?? widget.userEmail;
          _userPhone = userData['uphoneno']?.toString();
          _userAddress = userData['ucountry'];
          _userRole = userGroup;
          _storedPassword = userData['password']?.toString();
          _isLoading = false;

          _paypalController.text =
              (userData['paypalid'] ?? userData['paypal_email'] ?? '')
                  .toString();
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
          '/before-login',
          (route) => false,
        );
      }
    }
  }

  Future<void> _updatePaypal() async {
    final paypalEmail = _paypalController.text.trim();

    if (paypalEmail.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your PayPal email.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(paypalEmail)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final userid = await Session.getUserId();
      if (userid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (_fullUserData == null) {
        await _loadUserData();
        if (_fullUserData == null) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load user data. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final updateData = {
        'userid': userid,
        'paypalid': paypalEmail,
      };

      await api.updateProfile(updateData);

      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PayPal information updated successfully.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );

      _loadUserData();
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update PayPal email: ${error.toString()}'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
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

  String? get _effectiveRoleString {
    return (_userRole ?? _routeUserRole)?.toLowerCase();
  }

  nav.UserRole? get _userRoleEnum {
    return nav.userRoleFromString(_effectiveRoleString);
  }

  _PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;

    final hasNumber = RegExp(r'\d').hasMatch(password);
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (password.length < 6 || !hasNumber || !hasLetter) {
      return _PasswordStrength.weak;
    }
    if (password.length < 8 || !(hasNumber && hasLetter && hasSpecial)) {
      return _PasswordStrength.medium;
    }
    return _PasswordStrength.strong;
  }

  Widget _buildPasswordStrengthBar() {
    if (_passwordStrength == _PasswordStrength.none) {
      return const SizedBox.shrink();
    }

    double value;
    String label;
    Color color;

    switch (_passwordStrength) {
      case _PasswordStrength.weak:
        value = 0.33;
        label = 'Weak';
        color = Colors.redAccent;
        break;
      case _PasswordStrength.medium:
        value = 0.66;
        label = 'Medium';
        color = Colors.orangeAccent;
        break;
      case _PasswordStrength.strong:
        value = 1.0;
        label = 'Strong';
        color = Colors.green;
        break;
      case _PasswordStrength.none:
        value = 0.0;
        label = '';
        color = Colors.transparent;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

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
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const SizedBox(width: 0, height: 0),
        leadingWidth: 0,
        toolbarHeight: kToolbarHeight,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: headerColor,
      ),
      endDrawer: navRole != null && navRole != nav.UserRole.customer
          ? MoreMenuDrawer(
              role: navRole,
              onItemSelected: _handleMenuSelection,
              onLogout: _handleLogout,
              currentPageLabel: 'Profile',
            )
          : null,
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
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    color: headerColor.withOpacity(0.15),
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
                                  onPressed: _showEditProfileDialog,
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
                              color: Colors.black.withOpacity(0.04),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
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
                          style:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        onPressed: _handleLogout,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: navRole != null
          ? SharedBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onTap: _handleBottomNavTap,
              scaffoldKey: _scaffoldKey,
              role: navRole,
            )
          : null,
    );
  }

  /// Glassmorphism Edit Profile dialog with username, phone, and password
  Future<void> _showEditProfileDialog() async {
    _editUsernameController.text = _userName ?? widget.userName;
    _editPhoneController.text = _userPhone ?? '';
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _passwordStrength = _PasswordStrength.none;
    _showNewPassword = false;
    _showConfirmPassword = false;
    _isSavingDialog = false;

    final role = _userRole ?? _routeUserRole ?? 'customer';
    final Color accentColor = _getHeaderColor(role);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SlideTransition(
            position: _shakeAnimation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(dialogCtx).size.height * 0.8,
                    ),
                    child: SingleChildScrollView(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Edit Profile',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Update your username, phone, and password.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Username
                              const Text(
                                "Username",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _editUsernameController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter username',
                                    hintStyle: TextStyle(color: _textMuted),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: accentColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Phone Number
                              const Text(
                                "Phone Number",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _editPhoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: 'Enter phone number',
                                    hintStyle: TextStyle(color: _textMuted),
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color: accentColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // New Password
                              const Text(
                                "New Password (optional)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _newPasswordController,
                                  obscureText: !_showNewPassword,
                                  onChanged: (value) {
                                    setStateDialog(() {
                                      _passwordStrength =
                                          _calculatePasswordStrength(value);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                        'More than 6 characters, with numbers',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: _textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: accentColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showNewPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          _showNewPassword =
                                              !_showNewPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              // Strength meter
                              _buildPasswordStrengthBar(),

                              const SizedBox(height: 16),

                              // Confirm Password
                              const Text(
                                "Confirm Password",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Re-enter new password',
                                    hintStyle: TextStyle(
                                      fontSize: 12,
                                      color: _textMuted,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_reset_outlined,
                                      color: accentColor,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _showConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          _showConfirmPassword =
                                              !_showConfirmPassword;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogCtx).pop(),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _textMuted,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      child: const Text('Cancel'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSavingDialog
                                          ? null
                                          : () async {
                                              await _handleSaveFromDialog(
                                                dialogCtx,
                                                setStateDialog,
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                      ),
                                      child: _isSavingDialog
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.3,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Save',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handles validation + backend update when user taps "Save Changes" in dialog
  Future<void> _handleSaveFromDialog(
    BuildContext dialogCtx,
    void Function(void Function()) setStateDialog,
  ) async {
    final username = _editUsernameController.text.trim();
    final phone = _editPhoneController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Username validation: at least 6 characters
    if (username.length < 6) {
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(dialogCtx).showSnackBar(
        const SnackBar(
          content: Text('Username must be at least 6 characters.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Phone validation: digits only if not empty
    final phoneRegex = RegExp(r'^\d+$');
    if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(dialogCtx).showSnackBar(
        const SnackBar(
          content: Text('Phone number should only contain digits.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Password validation (optional)
    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword.length < 6 || !RegExp(r'\d').hasMatch(newPassword)) {
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(dialogCtx).showSnackBar(
          const SnackBar(
            content: Text(
              'Password must be at least 6 characters and include a number.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (newPassword != confirmPassword) {
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(dialogCtx).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // Get user id
    final userid = await Session.getUserId();
    if (userid == null) {
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(dialogCtx).showSnackBar(
        const SnackBar(
          content: Text('User not logged in.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Ensure we have full user data
    if (_fullUserData == null) {
      await _loadUserData();
      if (_fullUserData == null) {
        _shakeController.forward(from: 0);
        ScaffoldMessenger.of(dialogCtx).showSnackBar(
          const SnackBar(
            content: Text('Failed to load user data. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    // Build payload
    final updateData = _buildBaseUpdatePayload(userid);
    updateData['username'] = username;
    updateData['uphoneno'] = phone;
    if (newPassword.isNotEmpty) {
      updateData['password'] = newPassword;
    }

    setStateDialog(() {
      _isSavingDialog = true;
    });

    try {
      await api.updateProfile(updateData);

      if (!mounted) return;

      // Update local state to reflect immediately in UI
      setState(() {
        _userName = username;
        _userPhone = phone;
        if (newPassword.isNotEmpty) {
          _storedPassword = newPassword;
        }
      });

      Navigator.of(dialogCtx).pop(); // close dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setStateDialog(() {
        _isSavingDialog = false;
      });
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(dialogCtx).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleBottomNavTap(int index) async {
    final role = _userRoleEnum;
    if (role == null) return;

    if (index == 4) return;

    if (index == 0) {
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
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil(route, (route) => false);
      }
      return;
    }

    if (index == 1) {
      if (role == nav.UserRole.customer) {
        Navigator.of(context).pushReplacementNamed('/customer-cart');
      } else if (role == nav.UserRole.owner) {
        Navigator.of(context)
            .pushReplacementNamed('/owner-property-listing');
      } else {
        Navigator.of(context).pushReplacementNamed('/manage-services');
      }
      return;
    }

    if (index == 2) {
      if (role == nav.UserRole.customer) {
        Navigator.of(context).pushReplacementNamed('/customer-bookings');
      } else if (role == nav.UserRole.owner) {
        Navigator.of(context).pushReplacementNamed('/owner-reservation');
      } else {
        Navigator.of(context).pushReplacementNamed('/manage-booking');
      }
      return;
    }

    if (index == 3) {
      if (_selectedIndex != 3) {
        setState(() => _selectedIndex = 3);
      }
    }
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
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
          Navigator.of(context, rootNavigator: true)
              .pushNamedAndRemoveUntil(route, (route) => false);
        }
        break;
      case 'Profile':
        break;
      case 'Properties':
        if (role == nav.UserRole.owner) {
          Navigator.of(context)
              .pushReplacementNamed('/owner-property-listing');
        } else {
          Navigator.of(context).pushReplacementNamed('/manage-services');
        }
        break;
      case 'Bookings':
        if (role == nav.UserRole.owner) {
          Navigator.of(context).pushReplacementNamed('/owner-reservation');
        } else {
          Navigator.of(context).pushReplacementNamed('/manage-booking');
        }
        break;
      case 'Rooms':
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 'Cart':
        Navigator.of(context).pushReplacementNamed('/customer-cart');
        break;
      case 'Notifications':
        Navigator.of(context)
            .pushReplacementNamed('/customer-notifications');
        break;
      case 'User Management':
        final appRole =
            role == nav.UserRole.admin ? AppRole.admin : AppRole.moderator;
        Navigator.of(context).pushReplacementNamed(
          '/user-management',
          arguments: appRole,
        );
        break;
      case 'Customer':
        if (role == nav.UserRole.owner) {
          Navigator.of(context)
              .pushReplacementNamed('/owner-manage-customer');
        }
        break;
      case 'Moderator/Admin':
        if (role == nav.UserRole.owner) {
          Navigator.of(context)
              .pushReplacementNamed('/owner-manage-moderatoradmin');
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to $label',
                style: const TextStyle(color: Colors.black)),
            backgroundColor: const Color(0xFF468FAF),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

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
              color: color.withOpacity(0.12),
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
