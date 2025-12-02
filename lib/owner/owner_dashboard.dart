import 'package:flutter/material.dart';
import '../services/session.dart';
import '../services/rbac_service.dart' as rbac;
import '../api.dart' as api;
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../app.dart';
import 'owner_property_listing.dart';
import 'owner_reservation.dart';
import 'owner_manage_customer.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  static const String routeName = '/owner';

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

enum _StatCategory { user, booking, finance, cluster }

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _currentUserRole;

  _StatCategory _selectedCategory = _StatCategory.user;
  
  // Dashboard statistics
  int _totalUsers = 0;
  int _totalProperties = 0;
  int _totalReservations = 0;
  double _occupancyRate = 0.0;
  double _revPAR = 0.0;
  double _totalRevenue = 0.0;
  double _averageRevenue = 0.0;
  double _guestSatisfaction = 0.0;
  int _totalClusters = 0;
  bool _isLoadingStats = false;

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
    print('OwnerDashboard: Loading statistics at ${DateTime.now()}');
    print('═══════════════════════════════════════');

    // Fetch Total Users
    try {
      final customersData = await api.fetchCustomers();
      final customers = _extractList(customersData, ['customers', 'data', 'users']);
      
      final ownersData = await api.fetchOwners();
      final owners = _extractList(ownersData, ['owners', 'data', 'users']);
      
      final moderatorsData = await api.fetchModerators();
      final moderators = _extractList(moderatorsData, ['moderators', 'data', 'users']);
      
      final adminsData = await api.fetchAdministrators();
      final admins = _extractList(adminsData, ['administrators', 'admins', 'data', 'users']);
      
      final totalUsers = customers.length + owners.length + moderators.length + admins.length;
      
      if (mounted) {
        setState(() {
          _totalUsers = totalUsers;
        });
      }
      print('OwnerDashboard: Total users loaded: $_totalUsers');
    } catch (error) {
      print('OwnerDashboard: Error fetching users: $error');
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
      print('OwnerDashboard: Total properties loaded: $_totalProperties');
    } catch (error) {
      print('OwnerDashboard: Error fetching properties: $error');
    }

    // Fetch Total Reservations
    try {
      final reservations = await api.fetchReservation();
      
      if (mounted) {
        setState(() {
          _totalReservations = reservations.length;
        });
      }
      print('OwnerDashboard: Total reservations loaded: $_totalReservations');
    } catch (error) {
      print('OwnerDashboard: Error fetching reservations: $error');
    }

    // Fetch Total Clusters
    try {
      final clustersData = await api.fetchClusters();
      
      int clusterCount = 0;
      if (clustersData['clusters'] != null && clustersData['clusters'] is List) {
        clusterCount = (clustersData['clusters'] as List).length;
      } else if (clustersData is List) {
        clusterCount = clustersData.length;
      } else if (clustersData['data'] != null && clustersData['data'] is List) {
        clusterCount = (clustersData['data'] as List).length;
      }
      
      if (mounted) {
        setState(() {
          _totalClusters = clusterCount;
        });
      }
      print('OwnerDashboard: Total clusters loaded: $_totalClusters');
    } catch (error) {
      print('OwnerDashboard: Error fetching clusters: $error');
    }

    // Fetch Occupancy Rate, RevPAR, Revenue, Guest Satisfaction
    final userid = await Session.getUserId();
    if (userid != null) {
      try {
        final occupancyData = await api.fetchOccupancyRate(userid, paidOnly: true);
        print('OwnerDashboard: Occupancy data structure: ${occupancyData.keys.toList()}');
        
        double occupancyRate = 0.0;
        
        // Try direct value first
        if (occupancyData['occupancyRate'] != null) {
          occupancyRate = _parseDouble(occupancyData['occupancyRate']);
        } else if (occupancyData['rate'] != null) {
          occupancyRate = _parseDouble(occupancyData['rate']);
        } else if (occupancyData['value'] != null) {
          occupancyRate = _parseDouble(occupancyData['value']);
        } else if (occupancyData['monthlyData'] != null && occupancyData['monthlyData'] is List) {
          // Calculate from monthlyData
          final monthlyData = occupancyData['monthlyData'] as List;
          if (monthlyData.isNotEmpty) {
            print('OwnerDashboard: Occupancy monthlyData sample: ${monthlyData[0]}');
            print('OwnerDashboard: Occupancy month keys: ${(monthlyData[0] as Map).keys.toList()}');
            // Get the latest month's data (last item in array)
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
        print('OwnerDashboard: Occupancy rate loaded: $_occupancyRate%');
      } catch (error) {
        print('OwnerDashboard: Error fetching occupancy rate: $error');
      }

      try {
        final revPARData = await api.fetchRevPAR(userid, paidOnly: true);
        
        double revPAR = 0.0;
        if (revPARData['monthlyData'] != null && revPARData['monthlyData'] is List) {
          final monthlyData = revPARData['monthlyData'] as List;
          print('OwnerDashboard: RevPAR monthlyData: $monthlyData');
          if (monthlyData.isNotEmpty) {
            final latestMonth = monthlyData.last;
            print('OwnerDashboard: RevPAR latestMonth: $latestMonth');
            print('OwnerDashboard: RevPAR latestMonth keys: ${(latestMonth as Map).keys.toList()}');
            revPAR = _parseDouble(latestMonth['revpar']); // Backend uses 'revpar' (lowercase)
            print('OwnerDashboard: RevPAR raw value: ${latestMonth['revpar']}');
          }
        }
        
        if (mounted) {
          setState(() {
            _revPAR = revPAR;
          });
        }
        print('OwnerDashboard: RevPAR loaded: $_revPAR');
      } catch (error) {
        print('OwnerDashboard: Error fetching RevPAR: $error');
      }

      try {
        final financeData = await api.fetchFinance(userid, paidOnly: true);
        
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
        print('OwnerDashboard: Total revenue loaded: $_totalRevenue');
      } catch (error) {
        print('OwnerDashboard: Error fetching revenue: $error');
      }

      // Fetch Average Revenue (from backend)
      try {
        final avgRevenue = await api.fetchAverageRevenue(userid);
        if (mounted) {
          setState(() {
            _averageRevenue = avgRevenue;
          });
        }
        print('OwnerDashboard: Average revenue loaded: $_averageRevenue');
      } catch (error) {
        print('OwnerDashboard: Error fetching average revenue: $error');
      }

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
        print('OwnerDashboard: Guest satisfaction loaded: $_guestSatisfaction');
      } catch (error) {
        print('OwnerDashboard: Error fetching guest satisfaction: $error');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingStats = false;
      });
    }
    
    print('OwnerDashboard: Statistics loading complete');
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
                  colors: [Color(0xFF6366F1), Color(0xFF4188FF)],
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
                  const Text(
                    'Owner Dashboard',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Welcome, ${_currentUserRole != null ? rbac.RBACService.getRoleDisplayName(_currentUserRole!) : 'User'}',
                    style: const TextStyle(
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
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.owner,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Dashboard',
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

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('User', _StatCategory.user),
          const SizedBox(width: 8),
          _buildCategoryChip('Booking', _StatCategory.booking),
          const SizedBox(width: 8),
          _buildCategoryChip('Finance', _StatCategory.finance),
          const SizedBox(width: 8),
          _buildCategoryChip('Cluster', _StatCategory.cluster),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, _StatCategory category) {
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
      case _StatCategory.user:
        // User: total users
        cards.add(
          _buildStatCard(
            title: 'Total Users',
            value: '$_totalUsers',
            icon: Icons.people_outline,
            iconColor: const Color(0xFF8B5CF6),
            route: '/owner-manage-customer',
          ),
        );
        break;

      case _StatCategory.booking:
        // Booking: total properties, total reservations
        cards.add(
          _buildStatCard(
            title: 'Total Properties',
            value: '$_totalProperties',
            icon: Icons.apartment,
            iconColor: const Color(0xFF10B981),
            route: '/owner-property-listing',
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Total Reservations',
            value: '$_totalReservations',
            icon: Icons.calendar_today,
            iconColor: const Color(0xFF3B82F6),
            route: '/owner-reservation',
          ),
        );
        break;

      case _StatCategory.finance:
        // Finance: occupancy rate, revPAR, total revenue, guest satisfaction
        cards.add(
          _buildStatCard(
            title: 'Occupancy Rate',
            value: '${_occupancyRate.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            iconColor: const Color(0xFF8B5CF6),
            route: '/occupancy',
            showButton: false,
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'RevPAR',
            value: 'MYR ${_revPAR.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF8B5CF6),
            route: '/revpar',
            showButton: false,
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Total Revenue',
            value: 'MYR ${_totalRevenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            iconColor: const Color(0xFF10B981),
            route: '/revenue',
            showButton: false,
          ),
        );
        // Average Revenue card
        cards.add(
          _buildStatCard(
            title: 'Average Revenue',          
            value: 'MYR ${_averageRevenue.toStringAsFixed(2)}',           
            icon: Icons.pie_chart_outline,  
            iconColor: const Color(0xFF3B82F6),
            route: '/average-revenue',
            showButton: false, 
          ),
        );
        cards.add(
          _buildStatCard(
            title: 'Guest Satisfaction',
            value: '${_guestSatisfaction.toStringAsFixed(1)}/5.0',
            icon: Icons.bar_chart,
            iconColor: const Color(0xFFEF4444),
            route: '/satisfaction',
            showButton: false,
          ),
        );
        break;

      case _StatCategory.cluster:
        // Cluster: total clusters
        cards.add(
          _buildStatCard(
            title: 'Total Clusters',
            value: '$_totalClusters',
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFFEF4444),
            route: '/owner-cluster',
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
    bool showButton = true,
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 12),
            if (showButton)
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(route);
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
                    children: const [
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

  void _handleBottomNavTap(int index) {
    if (index == 4) {
      // More button - handled by SharedBottomNavigationBar to open drawer
      return;
    }
    if (index == 0) {
      // Dashboard - already on this page
      if (_selectedIndex != 0) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }
    if (index == 1) {
      // Properties
      Navigator.of(context).pushNamed('/owner-property-listing');
      return;
    }
    if (index == 2) {
      // Bookings/Reservations
      Navigator.of(context).pushNamed('/owner-reservation');
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.of(context).pushNamed('/profile');
      return;
    }
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
      Navigator.of(context).pushNamed('/owner-property-listing');
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      Navigator.of(context).pushNamed('/owner-reservation');
      return;
    }
    if (label == 'Customer') {
      Navigator.of(context).pushNamed('/owner-manage-customer');
      return;
    }
    if (label == 'Moderator/Admin') {
      Navigator.of(context).pushNamed('/owner-manage-moderatoradmin');
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
}
