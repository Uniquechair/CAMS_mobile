import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/rbac_service.dart' as rbac;
import '../app.dart';
import '../shared_admin_moderator/manage_service.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../api.dart' as api;
import 'moderator_notification.dart';

class ModeratorDashboard extends StatefulWidget {
  const ModeratorDashboard({super.key});
  static const String routeName = '/moderator';
  
  @override
  State<ModeratorDashboard> createState() => _ModeratorDashboardState();
}

enum _ModeratorStatCategory { user, booking, finance }

class _ModeratorDashboardState extends State<ModeratorDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentUserRole;
  
  _ModeratorStatCategory _selectedCategory = _ModeratorStatCategory.user;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _totalProperties = 0;
  int _totalReservations = 0;
  double _occupancyRate = 0.0;
  double _revPAR = 0.0;
  double _totalRevenue = 0.0;
  double _guestSatisfaction = 0.0;
  bool _isLoadingStats = false;

  void _openManageServices() {
    final nav = appNavigatorKey.currentState;
    try {
      // DEBUG
      // ignore: avoid_print
      print('MOD: _openManageServices invoked');
      if (nav != null) {
        // ignore: avoid_print
        print('MOD: using appNavigatorKey.pushNamed(/manage-services)');
        nav.pushNamed('/manage-services');
      } else {
        // ignore: avoid_print
        print('MOD: appNavigatorKey null, using rootNavigator.pushNamed(/manage-services)');
        Navigator.of(context, rootNavigator: true).pushNamed('/manage-services');
      }
    } catch (_) {
      // ignore: avoid_print
      print('MOD: named route failed, pushing ManageServicesPage directly');
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
    for (var key in possibleKeys) {
      if (data[key] != null && data[key] is List) {
        return List<dynamic>.from(data[key]);
      }
    }
    return [];
  }

  // Helper method to parse double values
  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    print('═══════════════════════════════════════');
    print('ModeratorDashboard: Loading statistics at ${DateTime.now()}');
    print('═══════════════════════════════════════');

    // Fetch Total Users
    try {
      final customersData = await api.fetchCustomers();
      final customers = _extractList(customersData, ['customers', 'data', 'users']);
      
      final moderatorsData = await api.fetchModerators();
      final moderators = _extractList(moderatorsData, ['moderators', 'data', 'users']);
      
      final adminsData = await api.fetchAdministrators();
      final admins = _extractList(adminsData, ['administrators', 'admins', 'data', 'users']);
      
      // Moderator dashboard does NOT include owners in total user count
      final totalUsers = customers.length + moderators.length + admins.length;
      
      if (mounted) {
        setState(() {
          _totalUsers = totalUsers;
        });
      }
      print('ModeratorDashboard: Total users loaded: $_totalUsers');
    } catch (error) {
      print('ModeratorDashboard: Error fetching users: $error');
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
      print('ModeratorDashboard: Total properties loaded: $_totalProperties');
    } catch (error) {
      print('ModeratorDashboard: Error fetching properties: $error');
    }

    // Fetch Total Reservations
    try {
      final reservations = await api.fetchReservation();
      
      if (mounted) {
        setState(() {
          _totalReservations = reservations.length;
        });
      }
      print('ModeratorDashboard: Total reservations loaded: $_totalReservations');
    } catch (error) {
      print('ModeratorDashboard: Error fetching reservations: $error');
    }

    // Fetch Occupancy Rate, RevPAR, Revenue, Guest Satisfaction
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
        print('ModeratorDashboard: Occupancy rate loaded: $_occupancyRate%');
      } catch (error) {
        print('ModeratorDashboard: Error fetching occupancy rate: $error');
      }

      try {
        final revPARData = await api.fetchRevPAR(userid);
        
        double revPAR = 0.0;
        if (revPARData['monthlyData'] != null && revPARData['monthlyData'] is List) {
          final monthlyData = revPARData['monthlyData'] as List;
          print('ModeratorDashboard: RevPAR monthlyData: $monthlyData');
          if (monthlyData.isNotEmpty) {
            final latestMonth = monthlyData.last;
            print('ModeratorDashboard: RevPAR latestMonth: $latestMonth');
            print('ModeratorDashboard: RevPAR latestMonth keys: ${(latestMonth as Map).keys.toList()}');
            revPAR = _parseDouble(latestMonth['revpar']); // Backend uses 'revpar' (lowercase)
            print('ModeratorDashboard: RevPAR raw value: ${latestMonth['revpar']}');
          }
        }
        
        if (mounted) {
          setState(() {
            _revPAR = revPAR;
          });
        }
        print('ModeratorDashboard: RevPAR loaded: $_revPAR');
      } catch (error) {
        print('ModeratorDashboard: Error fetching RevPAR: $error');
      }

      try {
        final financeData = await api.fetchFinance(userid);
        
        double revenue = 0.0;
        if (financeData['monthlyData'] != null && financeData['monthlyData'] is List) {
          final monthlyData = financeData['monthlyData'] as List;
          if (monthlyData.isNotEmpty) {
            // call backend api to get total revenue
            final latestMonth = monthlyData.last;
            revenue = _parseDouble(latestMonth['monthlyrevenue']);
          }
        }
        
        if (mounted) {
          setState(() {
            _totalRevenue = revenue;
          });
        }
        print('ModeratorDashboard: Total revenue loaded: $_totalRevenue');
      } catch (error) {
        print('ModeratorDashboard: Error fetching revenue: $error');
      }

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
      } catch (error) {
        print('ModeratorDashboard: Error fetching guest satisfaction: $error');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = false;
      });
    }
    
    print('ModeratorDashboard: Statistics loading complete');
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
                  colors: [Color(0xFF6366F1), Color(0xFF78AAFF)],
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
                    'Moderator Dashboard',
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModeratorNotifications()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
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

              _buildCategoryFilters(),
              const SizedBox(height: 16),

              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildBookingRequestQueue(),
            ],
          ),
        ),
      ),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.moderator,
        onItemSelected: _handleMenuSelection,
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: nav.UserRole.moderator,
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 4) {
      // More button - handled by SharedBottomNavigationBar to open drawer
      return;
    }
    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (index == 1) {
      Navigator.of(context).pushNamed('/manage-services');
      return;
    }
    if (index == 2) {
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

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('User', _ModeratorStatCategory.user),
          const SizedBox(width: 8),
          _buildCategoryChip('Booking', _ModeratorStatCategory.booking),
          const SizedBox(width: 8),
          _buildCategoryChip('Finance', _ModeratorStatCategory.finance),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, _ModeratorStatCategory category) {
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
    final List<Widget> cards = [];

    switch (_selectedCategory) {
      case _ModeratorStatCategory.user:
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

      case _ModeratorStatCategory.booking:
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

      case _ModeratorStatCategory.finance:
        // Finance: occupancy rate, revpar, total revenue, guest satisfaction
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
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min, 
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
                          overflow: TextOverflow.ellipsis,
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
                      color: Color(0xFF78AAFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildBookingRequestItem(   // TODO: change to dynamic data
            title: 'Kyle Miller',
            subtitle: 'Beach Resort',
            price: 'RM 400',
          ),
          _buildBookingRequestItem(
            title: 'Hannah Evans',
            subtitle: 'City Apartment',
            price: 'RM 600',
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
            colors: [Color(0xFF6366F1), Color(0xFF78AAFF)],
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

}
