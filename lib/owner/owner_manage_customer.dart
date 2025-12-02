import 'package:flutter/material.dart';
import '../services/session.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../app.dart';
import '../api.dart' as api;
import 'owner_dashboard.dart';
import 'owner_manage_moderatoradmin.dart';

class OwnerManageCustomers extends StatefulWidget {
  const OwnerManageCustomers({super.key});

  @override
  State<OwnerManageCustomers> createState() => _OwnerManageCustomersState();
}

class _OwnerManageCustomersState extends State<OwnerManageCustomers> {
  int _selectedIndex = -1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> allCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Only fetch customers for this page
      final customersData = await api.fetchCustomers();

      final List<Map<String, dynamic>> allUsers = [];

      // Process customers only
      final customers = _extractList(customersData, ['customers', 'users', 'data']);
      for (var user in customers) {
        final normalizedUser = _normalizeUser(user, 'Customer');
        // Only add if the role is actually Customer
        if (normalizedUser['role'] == 'Customer') {
          allUsers.add(normalizedUser);
        }
      }

      if (mounted) {
        setState(() {
          allCustomers = allUsers;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('OwnerManageCustomers: Error loading users: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load users: $error';
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> _extractList(dynamic source, List<String> keys) {
    if (source is List) return source;
    if (source is Map<String, dynamic>) {
      for (final key in keys) {
        final value = source[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  Map<String, dynamic> _normalizeUser(Map<String, dynamic> raw, String fallbackRole) {
    // Determine role
    final roleRaw = raw['usergroup'] ?? raw['role'] ?? raw['type'] ?? fallbackRole;
    String role = fallbackRole;
    if (roleRaw is String && roleRaw.trim().isNotEmpty) {
      final r = roleRaw.trim();
      if (r.toLowerCase().contains('admin')) {
        role = 'Administrator';
      } else if (r.toLowerCase().contains('moderator')) {
        role = 'Moderator';
      } else if (r.toLowerCase().contains('customer')) {
        role = 'Customer';
      } else {
        role = r;
      }
    }

    final uid = (raw['userid'] ?? raw['uid'] ?? raw['id'] ?? '').toString();
    final username = (raw['username'] ?? '').toString();

    // Name from firstname/lastname or "name" field
    final firstName = (raw['firstname'] ?? raw['firstName'] ?? raw['ufirstname'] ?? '').toString();
    final lastName = (raw['lastname'] ?? raw['lastName'] ?? raw['ulastname'] ?? '').toString();
    String name;
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      name = [firstName, lastName].where((p) => p.isNotEmpty).join(' ');
    } else {
      name = (raw['name'] ?? username).toString();
    }

    final email = (raw['email'] ?? raw['uemail'] ?? '').toString();
    // Check multiple field name variations for phone (backend uses 'uphoneno')
    final phone = (raw['uphoneno'] ?? raw['phone'] ?? raw['phoneNo'] ?? raw['phoneno'] ?? raw['uphone'] ?? '').toString();
    // If phone is empty or "N/A", set to empty string
    final phoneValue = phone.isEmpty || phone.toLowerCase() == 'n/a' 
        ? '' 
        : phone;
    final gender = (raw['gender'] ?? raw['ugender'] ?? 'N/A').toString();
    final country = (raw['country'] ?? raw['countryname'] ?? raw['ucountry'] ?? 'N/A').toString();

    // Status from uactivation
    final uactivation = raw['uactivation'] ?? raw['status'] ?? 'active';
    final isOnline = uactivation.toString().toLowerCase().contains('active') ||
                    uactivation.toString().toLowerCase() == '1' ||
                    uactivation.toString().toLowerCase() == 'true';

    return {
      'uid': uid,
      'userid': int.tryParse(uid) ?? 0,
      'username': username,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phoneValue,
      'gender': gender,
      'country': country,
      'role': role,
      'isOnline': isOnline,
    };
  }

  List<Map<String, dynamic>> get filteredCustomers {
    // Filter to only show customers (double-check role)
    final customerOnly = allCustomers
        .where((c) =>
            c['role'] != null &&
            c['role'].toString().toLowerCase() == 'customer')
        .toList();

    if (_searchController.text.isEmpty) {
      return customerOnly;
    }

    final query = _searchController.text.toLowerCase();
    return customerOnly.where((customer) {
      return customer['username'].toString().toLowerCase().contains(query) ||
          customer['name'].toString().toLowerCase().contains(query) ||
          customer['email'].toString().toLowerCase().contains(query) ||
          customer['role'].toString().toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    customer['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailField('First Name', customer['firstName'] ?? '—'),
              _buildDetailField('Last Name', customer['lastName'] ?? '—'),
              _buildDetailField('Email', customer['email'] ?? '—'),
              _buildDetailField('Phone Number', 
                (customer['phone'] != null && (customer['phone'] as String).isNotEmpty)
                  ? (customer['phone'] as String)
                  : '—'),
              _buildDetailField('Gender', customer['gender'] ?? '—'),
              _buildDetailField('Country', customer['country'] ?? '—'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog(Map<String, dynamic> customer) {
    String selectedRole = customer['role'] ?? 'Customer';
    final userid = customer['userid'] ?? int.tryParse(customer['uid']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: const Color(0xFFE7F0FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign Role to ${customer['name']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Select Role:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: Colors.white,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: Colors.white,
                      items: ['Customer', 'Moderator', 'Administrator'].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role,
                            style: const TextStyle(color: Color(0xFF1E293B)),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (userid == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invalid user ID'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          );

                          try {
                            // Call API to assign role
                            await api.assignRole(userid, selectedRole);
                            
                            // Close loading and dialog
                            if (mounted) {
                              Navigator.of(context).pop(); // Close loading
                              Navigator.of(dialogContext).pop(); // Close assign role dialog
                            }

                            // Reload data to get updated roles
                            await _loadData();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Role updated to $selectedRole'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (error) {
                            if (mounted) {
                              Navigator.of(context).pop(); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to assign role: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Assign Role',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      cursorColor: const Color(0xFF0077B6),
      decoration: InputDecoration(
        hintText: 'Search customers...',
        prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: _buildAppBar(),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.owner,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Customer',
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF0077B6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isWide
                  ? Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 300,
                          child: _buildSearchField(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSearchField(),
                      ],
                    ),
              const SizedBox(height: 24),
              _buildCustomerList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: nav.UserRole.owner,
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: Color(0xFF0077B6),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final customers = filteredCustomers;

    if (customers.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: double.infinity,
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: const [
                Icon(Icons.search_off, size: 64, color: Color(0xFFCBD5E1)),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try adjusting your search criteria',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: customers.map((c) => _buildCustomerCard(c)).toList(),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        const Color(0xFF4188FF).withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF0077B6),
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: customer['isOnline']
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${customer['username']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text (
                      'UID ${customer['uid']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildRoleBadge(customer['role']),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                color: Colors.white,
                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility,
                            size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'assign',
                    child: Row(
                      children: [
                        Icon(Icons.person_add,
                            size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('Assign Role'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'view') {
                    _showCustomerDetails(customer);
                  } else if (value == 'assign') {
                    _showAssignRoleDialog(customer);
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.email_outlined,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customer['email'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;

    switch (role) {
      case 'Customer':
        bgColor = const Color(0xFFDDEAFF);
        textColor = const Color(0xFF0066CC);
        break;
      case 'Moderator':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFF59E0B);
        break;
      case 'Administrator':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF8B5CF6);
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF4188FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'User Management',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Manage all users',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: const [],
    );
  }

  Future<void> _handleLogout() async {
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
      await Session.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
      }
    }
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      Navigator.of(context).pushReplacementNamed('/owner');
      return;
    }
    if (label == 'Customer') {
      // Already on this page
      return;
    }
    if (label == 'Moderator/Admin') {
      Navigator.of(context).pushNamed('/owner-manage-moderatoradmin');
      return;
    }
    if (label == 'Properties' || label == 'PropertyListing') {
      Navigator.of(context).pushReplacementNamed('/owner-property-listing');
      return;
    }
    if (label == 'Bookings' || label == 'Reservation') {
      Navigator.of(context).pushReplacementNamed('/owner-reservation');
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (label == 'AuditTrails') {
      Navigator.of(context).pushNamed('/owner-audit-trails');
      return;
    }
    if (label == 'BooknPayLog') {
      Navigator.of(context).pushNamed('/owner-book-and-pay');
      return;
    }
    if (label == 'Cluster') {
      Navigator.of(context).pushNamed('/owner-cluster');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to $label', style: const TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFF468FAF),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 4) {
      // More button - handled by SharedBottomNavigationBar to open drawer
      return;
    }
    if (index == 0) {
      // Dashboard
      Navigator.of(context).pushReplacementNamed('/owner');
      return;
    }
    if (index == 1) {
      // Properties
      Navigator.of(context).pushReplacementNamed('/owner-property-listing');
      return;
    }
    if (index == 2) {
      // Bookings
      Navigator.of(context).pushReplacementNamed('/owner-reservation');
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.of(context).pushNamed('/profile');
      return;
    }
  }
}
