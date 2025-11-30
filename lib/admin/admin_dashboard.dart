import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session.dart';
import '../services/rbac_service.dart' as rbac;
import '../app.dart';
import '../shared_admin_moderator/manage_service.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../api.dart' as api;
import 'admin_notification.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  static const String routeName = '/admin';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

enum _AdminStatCategory { user, booking, finance }

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentUserRole;

  _AdminStatCategory _selectedCategory = _AdminStatCategory.user;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _totalProperties = 0;
  int _totalReservations = 0;
  double _occupancyRate = 0.0;
  double _revPAR = 0.0;
  double _totalRevenue = 0.0;
  double _guestSatisfaction = 0.0;
  bool _isLoadingStats = false; // Start as false to show numbers immediately
  bool _isProcessingApproval = false;
  bool _isProcessingBooking = false;
  bool _isLoadingBookings = false;
  List<Map<String, dynamic>> _pendingListings = [];
  List<Map<String, dynamic>> _pendingBookings = [];

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
      Navigator.of(context, rootNavigator: true).pushNamed('/manage-services');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadDashboardStats();
    _loadPendingBookings();
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
      
      List<dynamic> properties = [];
      if (propertiesData['properties'] != null) {
        properties = List<dynamic>.from(propertiesData['properties']);
      } else if (propertiesData['data'] != null) {
        properties = List<dynamic>.from(propertiesData['data']);
      }
      final propertyCount = properties.length;

      final pendingRequests = properties
          .where((prop) {
            final status = (prop['propertystatus'] ?? prop['propertyStatus'] ?? '')
                .toString()
                .toLowerCase();
            final ownerRole = (prop['usergroup'] ?? prop['ownerrole'] ?? '')
                .toString()
                .toLowerCase();
            return status == 'pending' && ownerRole == 'moderator';
          })
          .map<Map<String, dynamic>>((prop) {
            return {
              'propertyid': prop['propertyid'],
              'propertyaddress': prop['propertyaddress'] ??
                  prop['propertyDescription'] ??
                  'Untitled Property',
              'owner': prop['username'] ??
                  '${prop['ufirstname'] ?? ''} ${prop['ulastname'] ?? ''}'.trim(),
              'cluster': prop['clustername'] ?? 'Unknown Cluster',
              'submittedAt': prop['timestamp'],
            };
          })
          .toList();
      
      if (mounted) {
        setState(() {
          _totalProperties = propertyCount;
          _pendingListings = pendingRequests;
        });
      }
      print('AdminDashboard: Total properties loaded: $_totalProperties');
      print('AdminDashboard: Pending property requests: ${pendingRequests.length}');
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
        final occupancyData = await api.fetchOccupancyRate(userid, paidOnly: true);
        
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
        final revPARData = await api.fetchRevPAR(userid, paidOnly: true);
        
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
        final financeData = await api.fetchFinance(userid, paidOnly: true);
        
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
        final satisfactionData = await api.fetchGuestSatisfactionScore(userid, paidOnly: true);
        
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

  Future<void> _loadPendingBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final reservations = await api.fetchReservationsForAdminModerator();
      
      // Filter for pending bookings only
      final pending = reservations.where((r) {
        final status = r['reservationstatus']?.toString().toLowerCase() ?? 
                      r['status']?.toString().toLowerCase() ?? 
                      r['reservationStatus']?.toString().toLowerCase() ?? '';
        return status == 'pending' || status == 'requested' || status == 'enquiry';
      }).toList();

      if (mounted) {
        setState(() {
          _pendingBookings = pending.map((r) => r as Map<String, dynamic>).toList();
          _isLoadingBookings = false;
        });
      }
      print('AdminDashboard: Loaded ${_pendingBookings.length} pending bookings');
    } catch (error) {
      print('AdminDashboard: Error loading pending bookings: $error');
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _pendingBookings = [];
        });
      }
    }
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
      // Navigate back to the before-login screen
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
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
                  'Welcome, ${_currentUserRole != null ? rbac.RBACService.getRoleDisplayName(_currentUserRole!) : 'User'}',
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
            onPressed: () {
              Navigator.of(context).pushNamed('/admin-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboardStats();
          await _loadPendingBookings();
        },
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

              // category filter bar
              _buildCategoryFilters(),
              const SizedBox(height: 16),

              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildApprovalQueue(),
              const SizedBox(height: 24),
              _buildBookingRequestQueue(),
            ],
          ),
        ),
      ),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.admin,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Dashboard',
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: nav.UserRole.admin,
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 4) {
      // More button - handled by SharedBottomNavigationBar to open drawer
      return;
    }
    if (index == 0) {
      // Dashboard - already on dashboard, just update selected index
      if (_selectedIndex != 0) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (index == 1) {
      // Properties
      Navigator.of(context).pushNamed('/manage-services');
      return;
    }
    if (index == 2) {
      // Bookings
      Navigator.of(context).pushNamed('/manage-booking');
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      // Already on dashboard
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (label == 'User Management') {
      // Navigate to user management page with admin role
      Navigator.of(context).pushNamed('/user-management', arguments: AppRole.admin);
      return;
    }
    if (label == 'PropertyListing' || label == 'Properties') {
      Navigator.of(context).pushNamed('/manage-services');
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      Navigator.of(context).pushNamed('/manage-booking');
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

  // filter chips row (User / Booking / Finance)
  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('User', _AdminStatCategory.user),
          const SizedBox(width: 8),
          _buildCategoryChip('Booking', _AdminStatCategory.booking),
          const SizedBox(width: 8),
          _buildCategoryChip('Finance', _AdminStatCategory.finance),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, _AdminStatCategory category) {
    final bool isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
      },
      selectedColor: const Color(0xFF0077B6),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0077B6) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    // Build cards based on the selected category
    final List<Widget> cards = [];

    switch (_selectedCategory) {
      case _AdminStatCategory.user:
        // User: total users
        cards.add(
          _buildStatCard(
            title: 'Total Users',
            value: '$_totalUsers',
            icon: Icons.people_outline,
            iconColor: const Color(0xFF8B5CF6),
            route: '/users',
          ),
        );
        break;

      case _AdminStatCategory.booking:
        // Booking: total properties, total reservations
        cards.add(
          _buildStatCard(
            title: 'Total Properties',
            value: '$_totalProperties',
            icon: Icons.apartment,
            iconColor: const Color(0xFF10B981),
            route: '/properties',
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Total Reservations',
            value: '$_totalReservations',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF3B82F6),
            route: '/reservations',
          ),
        );
        break;

      case _AdminStatCategory.finance:
        // Finance: occupancy rate, revPAR, total revenue, guest satisfaction
        cards.add(
          _buildStatCard(
            title: 'Occupancy Rate',
            value: '${_occupancyRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF8B5CF6),
            route: '/occupancy',
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'RevPAR',
            value: 'MYR ${_revPAR.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF8B5CF6),
            route: '/revpar',
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Total Revenue',
            value: 'MYR ${_totalRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            iconColor: const Color(0xFF10B981),
            route: '/revenue',
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Guest Satisfaction',
            value: '${_guestSatisfaction.toStringAsFixed(1)}/5.0',
            icon: Icons.bar_chart,
            iconColor: const Color(0xFFEF4444),
            route: '/satisfaction',
          ),
        );
        break;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: cards,
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
                  children: const [
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
                  onPressed: _pendingListings.isEmpty
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All pending requests are shown here'),
                            ),
                          );
                        },
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
          if (_pendingListings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: const [
                  Icon(Icons.verified_outlined, color: Color(0xFF94A3B8), size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No pending property requests',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._pendingListings.take(5).map(_buildApprovalItem),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(Map<String, dynamic> listing) {
    final propertyName = listing['propertyaddress'] ?? 'Untitled Property';
    final owner = listing['owner'] ?? 'Moderator';
    final cluster = listing['cluster'] ?? 'Unknown Cluster';
    final requestTime = _formatRequestTime(listing['submittedAt']);

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
        propertyName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$owner • $cluster',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
          if (requestTime != null)
            Text(
              requestTime,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          ElevatedButton(
            onPressed: _isProcessingApproval
                ? null
                : () => _handleApprovalDecision(listing, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1FAE5),
              foregroundColor: const Color(0xFF15803D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Approve'),
          ),
          OutlinedButton(
            onPressed: _isProcessingApproval
                ? null
                : () => _handleApprovalDecision(listing, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprovalDecision(
      Map<String, dynamic> listing, bool approve) async {
    if (_isProcessingApproval) return;
    final propertyId = listing['propertyid'];
    if (propertyId == null) return;

    final confirmed = await _showApprovalConfirmationDialog(
      title: approve ? 'Approve Property' : 'Reject Property',
      message: approve
          ? 'Approve ${listing['propertyaddress']} for listing?'
          : 'Reject ${listing['propertyaddress']}? This property will not be published.',
    );
    if (confirmed != true) return;

    setState(() => _isProcessingApproval = true);
    try {
      final newStatus = approve ? 'Available' : 'Rejected';
      await api.updatePropertyStatus(propertyId, newStatus);
      try {
        if (approve) {
          await api.propertyListingAccept(propertyId);
        } else {
          await api.propertyListingReject(propertyId);
        }
      } catch (notifyError) {
        print('AdminDashboard: approval notification failed: $notifyError');
      }

      if (mounted) {
        setState(() {
          _pendingListings
              .removeWhere((entry) => entry['propertyid'] == propertyId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Property approved successfully'
                  : 'Property rejected successfully',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Failed to approve property: $error'
                  : 'Failed to reject property: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingApproval = false);
      }
    }
  }

  Future<bool?> _showApprovalConfirmationDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String? _formatRequestTime(dynamic timestamp) {
    if (timestamp == null) return null;
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (_) {
      return null;
    }
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
                  children: const [
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
                  onPressed: () {
                    Navigator.of(context).pushNamed('/manage-booking');
                  },
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
          if (_isLoadingBookings)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pendingBookings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No pending bookings',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._pendingBookings.take(5).map((booking) => _buildBookingRequestItem(booking)),
        ],
      ),
    );
  }

  Widget _buildBookingRequestItem(Map<String, dynamic> booking) {
    final customerName = booking['customername'] ?? 
                        booking['customer'] ??
                        booking['username'] ?? 
                        booking['customer_name'] ??
                        '${booking['rcfirstname'] ?? ''} ${booking['rclastname'] ?? ''}'.trim() ??
                        'Customer';
    final propertyName = booking['propertyaddress'] ?? 
                        booking['property'] ?? 
                        booking['property_name'] ?? 
                        'Property';
    final price = booking['totalprice'] ?? 
                  booking['price'] ?? 
                  booking['total_price'] ?? 
                  0.0;
    final priceStr = price is num ? 'RM ${price.toStringAsFixed(2)}' : 'RM 0.00';

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
        customerName.toString(),
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        propertyName.toString(),
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
            priceStr,
            style: const TextStyle(
              color: Color.fromARGB(255, 10, 105, 239),
              fontSize: 11,
            ),
          ),
        ],
      ),
      onTap: () {
        _showBookingDetailsDialog(booking);
      },
    );
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    final customerName = booking['customername'] ?? 
                        booking['customer'] ??
                        booking['username'] ?? 
                        booking['customer_name'] ??
                        '${booking['rcfirstname'] ?? ''} ${booking['rclastname'] ?? ''}'.trim() ??
                        'Customer';
    final propertyName = booking['propertyaddress'] ?? 
                        booking['property'] ?? 
                        booking['property_name'] ?? 
                        'Property';
    final price = booking['totalprice'] ?? 
                  booking['price'] ?? 
                  booking['total_price'] ?? 
                  0.0;
    final priceStr = price is num ? 'RM ${price.toStringAsFixed(2)}' : 'RM 0.00';
    final checkIn = booking['checkindate'] ?? 
                   booking['checkindatetime'] ?? 
                   booking['check_in_date'] ?? 
                   'N/A';
    final checkOut = booking['checkoutdate'] ?? 
                    booking['checkoutdatetime'] ?? 
                    booking['check_out_date'] ?? 
                    'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: Text(
          'Booking Details',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Customer', customerName.toString()),
            _buildDetailRow('Property', propertyName.toString()),
            _buildDetailRow('Check-in', checkIn.toString()),
            _buildDetailRow('Check-out', checkOut.toString()),
            _buildDetailRow('Price', priceStr),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBookingDecision(booking, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBookingDecision(booking, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBookingDecision(
      Map<String, dynamic> booking, bool approve) async {
    if (_isProcessingBooking) return;
    final reservationId = booking['reservationid'];
    if (reservationId == null) return;

    final confirmed = await _showBookingConfirmationDialog(
      title: approve ? 'Approve Booking' : 'Reject Booking',
      message: approve
          ? 'Approve booking request for ${booking['property']}?'
          : 'Reject booking request for ${booking['property']}?',
    );
    if (confirmed != true) return;

    setState(() => _isProcessingBooking = true);
    try {
      final newStatus = approve ? 'Accepted' : 'Rejected';
      await api.updateReservationStatus(reservationId, newStatus);
      if (approve) {
        try {
          await api.acceptBooking(reservationId);
        } catch (notifyError) {
          print('AdminDashboard: booking approval notification failed: $notifyError');
        }
      }

      if (mounted) {
        await _loadPendingBookings();
        await _loadDashboardStats();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Booking approved successfully'
                  : 'Booking rejected successfully',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Failed to approve booking: $error'
                  : 'Failed to reject booking: $error',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingBooking = false);
      }
    }
  }

  Future<bool?> _showBookingConfirmationDialog({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String? _formatBookingDateRange(dynamic start, dynamic end) {
    try {
      if (start == null || end == null) return null;
      final startDate = DateTime.parse(start.toString());
      final endDate = DateTime.parse(end.toString());
      final formatter = DateFormat('dd MMM');
      return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(double? price) {
    final value = price ?? 0.0;
    return 'RM ${value.toStringAsFixed(2)}';
  }

  Widget _buildDrawer() { /* unchanged */ return Drawer(
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
                children: nav.drawerMenuItemsForRole(nav.UserRole.admin)
                    .asMap()
                    .entries
                    .map((entry) => _buildDrawerItem(
                          entry.value.icon,
                          entry.value.label,
                          entry.value.label == 'Dashboard',
                        ))
                    .toList(),
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
    ); }

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


}

