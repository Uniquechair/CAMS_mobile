import 'package:flutter/material.dart';
import 'admin_notification.dart';
import 'admin_dashboard.dart';
import 'admin_book_and_pay.dart';
import '../shared/navigation_menu.dart' as nav;
import '../shared/bottom_navigation_bar.dart';
import '../services/session.dart';
import '../api.dart' as api;
import '../app.dart';

class AdminAuditTrails extends StatefulWidget {
  const AdminAuditTrails({super.key});

  @override
  State<AdminAuditTrails> createState() => _AdminAuditTrailsState();
}

class _AdminAuditTrailsState extends State<AdminAuditTrails> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = -1;
  String? _currentUserRole;

  final TextEditingController _searchController = TextEditingController();
  String _selectedActionType = 'All Actions';

  int _currentPage = 1;
  final int _pageSize = 5;
  bool _isLoading = true;

  List<Map<String, dynamic>> allTrails = [];

  List<Map<String, dynamic>> get _filteredTrails {
    final query = _searchController.text.trim().toLowerCase();

    return allTrails.where((trail) {
      final byType = _selectedActionType == 'All Actions' ||
          trail['actionType'] == _selectedActionType;
      if (!byType) return false;

      if (query.isEmpty) return true;

      final text = [
        trail['entityType'],
        trail['entityId'].toString(),
        trail['action'],
        trail['actionType'],
        trail['actionedBy'],
        trail['timestamp'],
        trail['creatorId'].toString(),
        trail['httpMethod'],
      ].join(' ').toLowerCase();

      return text.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _currentPage = 1;
      });
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

      final auditData = await api.auditTrails(userid);
      
      if (mounted) {
        // First pass: collect all userids that need username lookup
        final Set<int> userIdsToFetch = {};
        final List<Map<String, dynamic>> tempTrails = [];
        
        if (auditData is List) {
          for (var log in auditData) {
            final actionedBy = log['username'] ?? log['actionedBy'] ?? log['actionedby'];
            final creatorId = log['userid'] ?? log['creatorid'] ?? 0;
            
            // If actionedBy is a number (userid), we need to fetch username
            if (actionedBy is num) {
              userIdsToFetch.add(actionedBy.toInt());
            } else if (actionedBy == null || actionedBy.toString().isEmpty || actionedBy == 'Unknown') {
              // If actionedBy is missing/invalid, try using creatorId
              if (creatorId is num && creatorId > 0) {
                userIdsToFetch.add(creatorId.toInt());
              }
            }
            
            tempTrails.add({
              'creatorId': creatorId,
              'entityType': log['entitytype'] ?? log['entityType'] ?? '',
              'entityId': log['entityid'] ?? log['entityId'] ?? 0,
              'action': log['action'] ?? '',
              'actionType': log['actiontype'] ?? log['actionType'] ?? '',
              'actionedBy': actionedBy,
              'actionedById': actionedBy is num ? actionedBy.toInt() : (creatorId is num ? creatorId.toInt() : null),
              'timestamp': log['timestamp'] ?? '',
              'httpMethod': log['actiontype'] ?? log['actionType'] ?? 'POST',
            });
          }
        }
        
        // Fetch usernames for all userids in parallel
        final Map<int, String> userIdToUsername = {};
        if (userIdsToFetch.isNotEmpty) {
          final futures = userIdsToFetch.map((uid) async {
            try {
              final userData = await api.fetchUserData(uid);
              return MapEntry(uid, userData['username']?.toString() ?? 'Unknown');
            } catch (e) {
              print('Error fetching username for userid $uid: $e');
              return MapEntry(uid, 'Unknown');
            }
          });
          
          final results = await Future.wait(futures);
          for (var entry in results) {
            userIdToUsername[entry.key] = entry.value;
          }
        }
        
        // Second pass: update actionedBy with usernames
        setState(() {
          allTrails.clear();
          for (var trail in tempTrails) {
            final actionedById = trail['actionedById'] as int?;
            if (actionedById != null && userIdToUsername.containsKey(actionedById)) {
              trail['actionedBy'] = userIdToUsername[actionedById]!;
            } else if (trail['actionedBy'] is num) {
              // If still a number and not in map, keep as is or show userid
              trail['actionedBy'] = 'User ${trail['actionedBy']}';
            } else if (trail['actionedBy'] == null || trail['actionedBy'].toString().isEmpty) {
              trail['actionedBy'] = 'Unknown';
            }
            // Remove temporary field
            trail.remove('actionedById');
            allTrails.add(trail);
          }
          // Reverse so newest is first
          allTrails = allTrails.reversed.toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching audit trails: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

    final allFiltered = _filteredTrails;
    final totalItems = allFiltered.length;
    final totalPages =
        (totalItems + _pageSize - 1) ~/ _pageSize == 0 ? 1 : (totalItems + _pageSize - 1) ~/ _pageSize;

    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalItems);
    final pageItems =
        totalItems == 0 ? <Map<String, dynamic>>[] : allFiltered.sublist(startIndex, endIndex);

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
                  colors: [Color(0xFF0077B6), Color(0xFF649EFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Audit Trails',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track system activities',
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
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF64748B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminNotifications()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.admin,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'AuditTrails',
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF649EFF),
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
                                  'Audit Trails',
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
                                'Audit Trails',
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
                    _buildTrailList(pageItems, totalItems, totalPages, currentPage),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: nav.UserRole.admin,
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search audit trails...',
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
                'Accept',
                'Reject',
                'Create',
                'Update',
                'Delete',
                'Assign',
                'Request',
                'Register',
                'Login',
                'Logout',
                'Suggest',
                'Notify',
              ].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(
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
                  _currentPage = 1;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTrailList(
    List<Map<String, dynamic>> trails,
    int totalItems,
    int totalPages,
    int currentPage,
  ) {
    if (totalItems == 0) {
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

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trails.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final trail = trails[index];
            return _buildTrailCard(trail);
          },
        ),
        const SizedBox(height: 12),
        _buildPagination(totalPages, currentPage),
      ],
    );
  }

  Widget _buildTrailCard(Map<String, dynamic> trail) {
    final username = trail['actionedBy'] ?? 'Unknown';

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
            child: const Icon(Icons.history, size: 22, color: Color(0xFF649EFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trail['action'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      trail['actionedBy'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      trail['timestamp'] ?? '',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trail['actionType'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF649EFF),
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
                    _showTrailDetailsDialog(trail);
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

  Widget _buildPagination(int totalPages, int currentPage) {
    if (totalPages <= 1) return const SizedBox.shrink();

    List<int> pages;
    if (totalPages <= 5) {
      pages = List.generate(totalPages, (i) => i + 1);
    } else {
      final set = <int>{1, totalPages, currentPage - 1, currentPage, currentPage + 1};
      set.removeWhere((p) => p < 1 || p > totalPages);
      pages = set.toList()..sort();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    _currentPage = currentPage - 1;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        ..._buildPageButtons(pages, currentPage, totalPages),
        IconButton(
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    _currentPage = currentPage + 1;
                  });
                }
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  List<Widget> _buildPageButtons(
      List<int> pages, int currentPage, int totalPages) {
    final List<Widget> widgets = [];

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];

      if (i > 0 && page != pages[i - 1] + 1) {
        widgets.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...'),
        ));
      }

      final isSelected = page == currentPage;

      widgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _currentPage = page;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '$page',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _showTrailDetailsDialog(Map<String, dynamic> trail) {
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
                    'Audit Trail Details',
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
              _buildDetailField('Creator ID', trail['creatorId'].toString()),
              _buildDetailField('Actioned By', trail['actionedBy']),
              _buildDetailField('Entity ID', trail['entityId'].toString()),
              _buildDetailField('Entity Type', trail['entityType']),
              _buildDetailField('Timestamp', trail['timestamp']),
              _buildDetailField('Action', trail['action']),
              _buildDetailField('Action Type', trail['httpMethod']),
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
      Navigator.of(context).pushNamed('/admin');
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
    if (label == 'AuditTrails') {
      // Already on audit trails
      return;
    }
    if (label == 'Dashboard') {
      Navigator.of(context).pushNamed('/admin');
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (label == 'User Management') {
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
    if (label == 'BooknPayLog') {
      Navigator.of(context).pushNamed('/admin-book-and-pay');
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
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

