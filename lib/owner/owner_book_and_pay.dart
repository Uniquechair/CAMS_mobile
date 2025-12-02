import 'package:flutter/material.dart';
import 'owner_dashboard.dart';
import 'owner_manage_customer.dart';
import 'owner_manage_moderatoradmin.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../services/session.dart';
import '../api.dart' as api;
import '../app.dart';

class OwnerBooknPayLog extends StatefulWidget {
  const OwnerBooknPayLog({super.key});

  @override
  State<OwnerBooknPayLog> createState() => _OwnerBooknPayLogState();
}

class _OwnerBooknPayLogState extends State<OwnerBooknPayLog> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = -1;
  String? _currentUserRole;

  final TextEditingController _searchController = TextEditingController();
  String _selectedActionType = 'All Actions';
  bool _isLoading = true;

  List<Map<String, dynamic>> allLogs = [];

  List<Map<String, dynamic>> get filteredLogs {
    final query = _searchController.text.trim().toLowerCase();

    return allLogs.where((log) {
      final byType = _selectedActionType == 'All Actions' ||
          log['actionType'] == _selectedActionType;
      if (!byType) return false;

      if (query.isEmpty) return true;

      final text = [
        log['timestamp'],
        log['action'],
        log['actionedBy'],
        log['userId'].toString(),
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userid = await Session.getUserId();
      if (userid == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final logsData = await api.fetchBookAndPayLogs(userid);
      
      if (mounted) {
        setState(() {
          allLogs.clear();
          
          if (logsData is List) {
            for (var log in logsData) {
              // Map API response to expected format
              allLogs.add({
                'userId': log['userid'] ?? log['userId'] ?? 0,
                'timestamp': log['timestamp'] ?? log['createdat'] ?? log['createdAt'] ?? '',
                'action': log['action'] ?? log['message'] ?? log['description'] ?? '',
                'actionedBy': log['username'] ?? log['actionedBy'] ?? log['actionedby'] ?? 'Unknown',
                'actionType': _mapActionType(log['actiontype'] ?? log['actionType'] ?? log['action'] ?? ''),
              });
            }
            // Reverse so newest is first
            allLogs = allLogs.reversed.toList();
          }
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching book and pay logs: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Show error message to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load book and pay logs. Please check if the backend endpoint is implemented.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        });
      }
    }
  }

  String _mapActionType(dynamic actionType) {
    if (actionType == null) return 'Update';
    final type = actionType.toString().toLowerCase();
    if (type.contains('create') || type.contains('created')) return 'Create';
    if (type.contains('payment') || type.contains('paid') || type.contains('pay')) return 'Payment';
    if (type.contains('request') || type.contains('booking')) return 'Request';
    if (type.contains('delete') || type.contains('remove')) return 'Delete';
    if (type.contains('update') || type.contains('modified')) return 'Update';
    return 'Update';
  }

  Future<void> _loadUserRole() async {
    final userRole = await Session.getUserGroup();
    setState(() {
      _currentUserRole = userRole;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

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
                  colors: [Color(0xFF0077B6), Color(0xFF4188FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Book & Pay Log',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Monitor BnP activities',
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
        currentPageLabel: 'BooknPayLog',
      ),

      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4188FF),
                ),
              )
            : SingleChildScrollView(
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
                            'Book & Pay Log',
                            style: TextStyle(
                              fontSize: 24,
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
                          'Book & Pay Log',
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
                    const SizedBox(height: 16),
                    _buildFilterCard(),
                    const SizedBox(height: 16),
                    _buildLogList(filteredLogs),
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search logs...',
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

  Widget _buildFilterCard() {
    return Container(
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
          const Text(
            'Action Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _selectedActionType,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: Colors.white,
              items: const [
                'All Actions',
                'Create',
                'Request',
                'Payment',
                'Update',
                'Delete',
              ].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedActionType = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return Container(
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
              'No data found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try changing the filters or search keyword.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
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
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long,
                size: 22, color: Color(0xFF4188FF)),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['actionedBy'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  log['action'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      log['timestamp'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log['actionType'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4188FF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              PopupMenuButton<String>(
                color: Colors.white,
                icon: const Icon(Icons.more_horiz, color: Color(0xFF64748B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'view') {
                    _showLogDetailsDialog(log);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: const [
                        Icon(
                          Icons.visibility,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogDetailsDialog(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFE7F0FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Details',
                    style: TextStyle(
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
              const SizedBox(height: 16),
              _buildDetailField('UserId', log['userId'].toString()),
              _buildDetailField('Timestamp', log['timestamp']),
              _buildDetailField('Action', log['action']),
              _buildDetailField('Actioned By', log['actionedBy']),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
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
      Navigator.of(context).pushNamed('/owner');
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.of(context).pushNamed('/profile');
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
    setState(() => _selectedIndex = index);
  }

  void _handleMenuSelection(String label) {
    if (label == 'BooknPayLog') {
      // Already on book and pay log
      return;
    }
    if (label == 'Dashboard') {
      Navigator.of(context).pushNamed('/owner');
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
    if (label == 'Cluster') {
      Navigator.of(context).pushNamed('/owner-cluster');
      return;
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
      // Clear the session data
      await Session.clear();
      if (mounted) {
        // Navigate back to the before-login screen
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
      }
    }
  }
}
