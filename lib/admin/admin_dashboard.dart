import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/rbac_service.dart';
import '../app.dart';
import '../shared_admin_moderator/manage_service.dart';
import '../api.dart' as api;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  static const String routeName = '/admin';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentUserRole;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _totalProperties = 0;
  int _totalReservations = 0;
  double _occupancyRate = 0.0;
  double _revPAR = 0.0;
  double _totalRevenue = 0.0;
  double _guestSatisfaction = 0.0;
  bool _isLoadingStats = false; // Start as false to show numbers immediately

  void _openManageServices() {
    final nav = appNavigatorKey.currentState;
    try {
      // DEBUG
      // ignore: avoid_print
      print('ADMIN: _openManageServices invoked');
      if (nav != null) {
        // ignore: avoid_print
        print('ADMIN: using appNavigatorKey.pushNamed(/manage-services)');
        nav.pushNamed('/manage-services');
      } else {
        // ignore: avoid_print
        print('ADMIN: appNavigatorKey null, using rootNavigator.pushNamed(/manage-services)');
        Navigator.of(context, rootNavigator: true).pushNamed('/manage-services');
      }
    } catch (_) {
      // ignore: avoid_print
      print('ADMIN: named route failed, pushing ManageServicesPage directly');
      // Fallback to direct push if named route not found
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => const ManageServicesPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadDashboardStats();
  }

  Future<void> _loadUserRole() async {
    final userRole = await Session.getUserGroup();
    setState(() {
      _currentUserRole = userRole;
    });
  }

  // Helper method to extract list from different possible keys
  List<dynamic> _extractList(Map<String, dynamic> data, List<String> possibleKeys) {
    // Try each possible key
    for (var key in possibleKeys) {
      if (data[key] != null && data[key] is List) {
        print('AdminDashboard: Found data in key "$key" with ${(data[key] as List).length} items');
        return List<dynamic>.from(data[key]);
      }
    }
    
    // If no key matches, log what's available
    print('AdminDashboard: Could not find list in keys $possibleKeys');
    print('AdminDashboard: Available keys: ${data.keys.toList()}');
    data.forEach((key, value) {
      print('   $key: ${value.runtimeType} ${value is List ? "(length: ${value.length})" : ""}');
    });
    
    return [];
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    print('═══════════════════════════════════════');
    print('AdminDashboard: Loading statistics at ${DateTime.now()}');
    print('═══════════════════════════════════════');

    // Fetch Total Users
    try {
      print('AdminDashboard: Fetching users data...');
      
      final customersData = await api.fetchCustomers();
      final customers = _extractList(customersData, ['customers', 'data', 'users']);
      print('AdminDashboard: Customers count: ${customers.length}');
      
      final moderatorsData = await api.fetchModerators();
      final moderators = _extractList(moderatorsData, ['moderators', 'data', 'users']);
      print('AdminDashboard: Moderators count: ${moderators.length}');
      
      final adminsData = await api.fetchAdministrators();
      final admins = _extractList(adminsData, ['administrators', 'admins', 'data', 'users']);
      print('AdminDashboard: Administrators count: ${admins.length}');
      
      // Admin dashboard does NOT include owners in total user count
      final totalUsers = customers.length + moderators.length + admins.length;
      
      if (mounted) {
        setState(() {
          _totalUsers = totalUsers;
        });
      }
      print('AdminDashboard: Total users loaded: $_totalUsers');
    } catch (error) {
      print('AdminDashboard: Error fetching users: $error');
    }

    // Fetch Total Properties
    try {
      final propertiesData = await api.fetchPropertiesListingTable();
      
      int propertyCount = 0;
      if (propertiesData['properties'] != null) {
        propertyCount = (propertiesData['properties'] as List).length;
      } else if (propertiesData['data'] != null) {
        propertyCount = (propertiesData['data'] as List).length;
      }
      
      if (mounted) {
        setState(() {
          _totalProperties = propertyCount;
        });
      }
      print('AdminDashboard: Total properties loaded: $_totalProperties');
    } catch (error) {
      print('AdminDashboard: Error fetching properties: $error');
    }

    // Fetch Total Reservations
    try {
      final reservations = await api.fetchReservation();
      
      if (mounted) {
        setState(() {
          _totalReservations = reservations.length;
        });
      }
      print('AdminDashboard: Total reservations loaded: $_totalReservations');
    } catch (error) {
      print('AdminDashboard: Error fetching reservations: $error');
    }

    // Fetch Occupancy Rate
    final userid = await Session.getUserId();
    if (userid != null) {
      try {
        final occupancyData = await api.fetchOccupancyRate(userid);
        
        double occupancyRate = 0.0;
        if (occupancyData['occupancyRate'] != null) {
          occupancyRate = _parseDouble(occupancyData['occupancyRate']);
        } else if (occupancyData['monthlyData'] != null && occupancyData['monthlyData'] is List) {
          final monthlyData = occupancyData['monthlyData'] as List;
          if (monthlyData.isNotEmpty) {
            print('AdminDashboard: Occupancy monthlyData sample: ${monthlyData[0]}');
            print('AdminDashboard: Occupancy month keys: ${(monthlyData[0] as Map).keys.toList()}');
            final latestMonth = monthlyData.last;
            occupancyRate = _parseDouble(
              latestMonth['occupancy_rate'] ?? 
              latestMonth['occupancyRate'] ?? 
              latestMonth['rate'] ?? 
              latestMonth['value']
            );
          }
        }
        
        if (mounted) {
          setState(() {
            _occupancyRate = occupancyRate;
          });
        }
        print('AdminDashboard: Occupancy rate loaded: $_occupancyRate%');
      } catch (error) {
        print('AdminDashboard: Error fetching occupancy rate: $error');
      }

      // Fetch RevPAR
      try {
        final revPARData = await api.fetchRevPAR(userid);
        
        double revPAR = 0.0;
        if (revPARData['monthlyData'] != null && revPARData['monthlyData'] is List) {
          final monthlyData = revPARData['monthlyData'] as List;
          print('AdminDashboard: RevPAR monthlyData: $monthlyData');
          if (monthlyData.isNotEmpty) {
            final latestMonth = monthlyData.last;
            print('AdminDashboard: RevPAR latestMonth: $latestMonth');
            print('AdminDashboard: RevPAR latestMonth keys: ${(latestMonth as Map).keys.toList()}');
            revPAR = _parseDouble(latestMonth['revpar']); // Backend uses 'revpar' (lowercase)
            print('AdminDashboard: RevPAR raw value: ${latestMonth['revpar']}');
          }
        }
        
        if (mounted) {
          setState(() {
            _revPAR = revPAR;
          });
        }
        print('AdminDashboard: RevPAR loaded: $_revPAR');
      } catch (error) {
        print('AdminDashboard: Error fetching RevPAR: $error');
      }

      // Fetch Total Revenue
      try {
        final financeData = await api.fetchFinance(userid);
        
        double revenue = 0.0;
        if (financeData['monthlyData'] != null && financeData['monthlyData'] is List) {
          final monthlyData = financeData['monthlyData'] as List;
          if (monthlyData.isNotEmpty) {
            // call bac
            final latestMonth = monthlyData.last;
            revenue = _parseDouble(latestMonth['monthlyrevenue']);
          }
        }
        
        if (mounted) {
          setState(() {
            _totalRevenue = revenue;
          });
        }
        print('AdminDashboard: Total revenue loaded: $_totalRevenue');
      } catch (error) {
        print('AdminDashboard: Error fetching revenue: $error');
      }

      // Fetch Guest Satisfaction
      try {
        final satisfactionData = await api.fetchGuestSatisfactionScore(userid);
        
        double satisfaction = 0.0;
        if (satisfactionData['monthlyData'] != null && satisfactionData['monthlyData'] is List) {
          final monthlyData = satisfactionData['monthlyData'] as List;
          if (monthlyData.isNotEmpty) {
            // call backend api to get guest satisfaction score
            final latestMonth = monthlyData.last;
            satisfaction = _parseDouble(latestMonth['guest_satisfaction_score']);
          }
        }
        
        if (mounted) {
          setState(() {
            _guestSatisfaction = satisfaction;
          });
        }
        print('AdminDashboard: Guest satisfaction loaded: $_guestSatisfaction');
      } catch (error) {
        print('AdminDashboard: Error fetching guest satisfaction: $error');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = false;
      });
    }
    
    print('AdminDashboard: Statistics loading complete');
  }

  // Helper method to parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
    // Clear the session data
    await Session.clear();
    if (mounted) {
      // Navigate back to the login screen and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF649EFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dashboard, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome, ${_currentUserRole != null ? RBACService.getRoleDisplayName(_currentUserRole!) : 'User'}',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        color: const Color(0xFF0077B6),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Platform Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Monitor platform statistics and pending approvals',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildApprovalQueue(),
              const SizedBox(height: 24),
              _buildBookingRequestQueue(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildStatCard(
          title: 'Total Users',
          value: '$_totalUsers',
          icon: Icons.people_outline,
          iconColor: const Color(0xFF8B5CF6),
          route: '/users',
        ),
        _buildStatCard(
          title: 'Total Properties',
          value: '$_totalProperties',
          icon: Icons.apartment,
          iconColor: const Color(0xFF10B981),
          route: '/properties',
        ),
        _buildStatCard(
          title: 'Total Reservations',
          value: '$_totalReservations',
          icon: Icons.calendar_today,
          iconColor: const Color(0xFF3B82F6),
          route: '/reservations',
        ),
        _buildStatCard(
          title: 'Occupancy Rate',
          value: '${_occupancyRate.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          iconColor: const Color(0xFF8B5CF6),
          route: '/occupancy',
        ),
        _buildStatCard(
          title: 'RevPAR',
          value: 'MYR ${_revPAR.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet,
          iconColor: const Color(0xFF8B5CF6),
          route: '/revpar',
        ),
        _buildStatCard(
          title: 'Total Revenue',
          value: 'MYR ${_totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          iconColor: const Color(0xFF10B981),
          route: '/revenue',
        ),
        _buildStatCard(
          title: 'Guest Satisfaction',
          value: '${_guestSatisfaction.toStringAsFixed(1)}/5.0',
          icon: Icons.bar_chart,
          iconColor: const Color(0xFFEF4444),
          route: '/satisfaction',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String route,
  }) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Navigating to $title page', style: TextStyle(color: Colors.black)),
                      backgroundColor: const Color(0xFF468FAF),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  if (route == '/manage-services') {
                    Navigator.pushNamed(context, '/manage-services');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Center keeps the content centered even though the button is full width.
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // let contents size themselves
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Flexible is now INSIDE a Row (valid)
                      Flexible(
                        child: Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          softWrap: false,
                          overflow: TextOverflow.ellipsis, // prevent overflow
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalQueue() {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Approval Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pending moderator requests',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF649EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildApprovalItem(   // TODO: change to dynamic data
            title: 'Ocean View Suite',
            subtitle: 'Chris M. • New Listing',
            time: '2h ago',
          ),
          _buildApprovalItem(
            title: 'Mountain Cabin',
            subtitle: 'Alex B. • Price Update',
            time: '3h ago',
          ),
          _buildApprovalItem(
            title: 'City Apartment',
            subtitle: 'Sam K. • Availability',
            time: '1d ago',
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem({
    required String title,
    required String subtitle,
    required String time,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF649EFF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.apartment, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(245, 245, 198, 9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildBookingRequestQueue() {
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Awaiting for approval or rejection',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF649EFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildBookingRequestItem(   // TODO: change to dynamic data
            title: 'John Smith',
            subtitle: 'Seaside Villa',
            price: 'RM 1,000',
          ),
          _buildBookingRequestItem(
            title: 'Serah Johnson',
            subtitle: 'Mountain Retreat',
            price: 'RM 750',
          ),
        ],
      ),
    );
  }

  Widget _buildBookingRequestItem({
    required String title,
    required String subtitle,
    required String price,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF649EFF)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.apartment, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(29, 221, 8, 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: Color.fromARGB(255, 10, 105, 239),
              fontSize: 11,
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }

  Widget _buildDrawer() {
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF649EFF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Administrator',
                    style: TextStyle(
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
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', true),
                  _buildDrawerItem(Icons.people, 'Customer', false),
                  _buildDrawerItem(Icons.supervised_user_circle, 'Moderator', false),
                  _buildDrawerItem(Icons.admin_panel_settings, 'Administrator', false),
                  _buildDrawerItem(Icons.apartment, 'PropertyListing', false),
                  _buildDrawerItem(Icons.calendar_today, 'Reservation', false),
                  _buildDrawerItem(Icons.receipt_long, 'BooknPayLog', false),
                  _buildDrawerItem(Icons.history, 'AuditTrails', false),
                  _buildDrawerItem(Icons.trending_up, 'Finance', false),
                  _buildDrawerItem(Icons.person, 'Profile', false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF649EFF) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigating to $title', style: TextStyle(color: Colors.black)),
              backgroundColor: const Color(0xFF468FAF),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF649EFF),
        unselectedItemColor: const Color(0xFF94A3B8),
        onTap: (index) {
          // ignore: avoid_print
          print('ADMIN: BottomNavigationBar onTap index=' + index.toString());
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
            return;
          }
          if (index == 3) {
            // Profile page will fetch user data from API automatically
            Navigator.of(context).pushNamed('/profile');
            return;
          }
          if (index == 1) {
            // Properties -> Manage Services
            // ignore: avoid_print
            print('ADMIN: BottomNavigationBar opening Manage Services');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Manage Services...', style: TextStyle(color: Colors.black)),
                backgroundColor: Color(0xFF468FAF),
                duration: Duration(seconds: 1),
              ),
            );
            // Try named route first, fallback to direct push
            Future.microtask(() {
              try {
                Navigator.of(context).pushNamed('/manage-services');
                // ignore: avoid_print
                print('ADMIN: Navigation to /manage-services completed');
              } catch (e) {
                // ignore: avoid_print
                print('ADMIN: Named route failed: $e, trying direct push');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageServicesPage()),
                );
              }
            });
            return;
          }
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.room_service), label: 'Properties'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // ignore: avoid_print
          print('ADMIN: bottom nav tapped index=' + index.toString());
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else if (index == 1) {
            // Properties -> Manage Services
            // ignore: avoid_print
            print('ADMIN: navigating to Manage Services from bottom Properties');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening Manage Services...', style: TextStyle(color: Colors.black)),
                backgroundColor: Color(0xFF468FAF),
                duration: Duration(seconds: 1),
              ),
            );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageServicesPage()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF649EFF) : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF649EFF) : const Color(0xFF94A3B8),
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