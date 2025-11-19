import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session.dart';
import '../app.dart';
import 'manage_service.dart';
import '../shared/navigation_menu.dart';
import '../shared/bottom_navigation_bar.dart';

class AdminManageBooking extends StatefulWidget {
  const AdminManageBooking({super.key});

  @override
  State<AdminManageBooking> createState() => _AdminManageBookingState();
}

class _AdminManageBookingState extends State<AdminManageBooking> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;
  String _selectedStatus = 'All Statuses';
  bool _isCalendarView = true;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _currentUserRole;
  
    // Hardcoded booking data
    final List<Map<String, dynamic>> _bookings = [
      {
        'property': 'Sunrise Villa',
        'customer': 'Alice',
        'start': DateTime(2025, 11, 5),
        'end': DateTime(2025, 11, 8),
        'price': 'RM 3.3',
        'status': 'Accepted',
      },
      {
        'property': 'Blue Lagoon',
        'customer': 'Bob',
        'start': DateTime(2025, 11, 5),
        'end': DateTime(2025, 11, 6),
        'price': 'RM 2.0',
        'status': 'Pending',
      },
      {
        'property': 'Green Cottage',
        'customer': 'Charlie',
        'start': DateTime(2025, 11, 7),
        'end': DateTime(2025, 11, 9),
        'price': 'RM 4.5',
        'status': 'Rejected',
      },
    ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userRole = await Session.getUserGroup();
    setState(() {
      _currentUserRole = userRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      endDrawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildStatusFilter(),
              const SizedBox(height: 16),
              _buildViewToggle(),
              const SizedBox(height: 16),
              _isCalendarView ? _buildCalendarView() : _buildTableView(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _drawerRole != null ? SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: _drawerRole!,
      ) : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    // Determine theme color based on user role
    final isAdmin = _currentUserRole == 'admin';
    final themeColor = isAdmin ? const Color(0xFF649EFF) : const Color(0xFF78AAFF);
    final gradientColors = isAdmin 
        ? const [Color(0xFF6366F1), Color(0xFF649EFF)]
        : const [Color(0xFF6366F1), Color(0xFF78AAFF)];
    final dashboardTitle = isAdmin ? 'Admin Dashboard' : 'Moderator Dashboard';
    
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Color(0xFF64748B)),
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manage Bookings',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dashboardTitle,
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
          onPressed: () async {
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
              await Session.clear();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by property or customer name...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedStatus,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: const [
          DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses')),
          DropdownMenuItem(value: 'Pending', child: Text('Pending')),
          DropdownMenuItem(value: 'Accepted', child: Text('Accepted')),
          DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
          DropdownMenuItem(value: 'Canceled', child: Text('Canceled')),
          DropdownMenuItem(value: 'Paid', child: Text('Paid')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedStatus = value!;
          });
        },
      ),
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isCalendarView = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCalendarView ? const Color(0xFF0077B6) : Colors.white,
              foregroundColor: _isCalendarView ? Colors.white : const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Calendar View',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isCalendarView = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: !_isCalendarView ? const Color(0xFF0077B6) : Colors.white,
              foregroundColor: !_isCalendarView ? Colors.white : const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Table View',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCalendarHeader(),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Text('Today', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedDate),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        Row(
          children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startingWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startingWeekday) {
              return const SizedBox.shrink();
            }
            final day = index - startingWeekday + 1;
            final currentDate = DateTime.now();
            final isToday = day == currentDate.day &&
                _selectedDate.month == currentDate.month &&
                _selectedDate.year == currentDate.year;
            final isSelected = day == _selectedDate.day &&
                _selectedDate.month == _selectedDate.month &&
                _selectedDate.year == _selectedDate.year;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, day);
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFF649EFF) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarLegend() {
    return Row(
      children: [
        _buildLegendItem(const Color(0xFFFBBF24), 'Pending'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFF10B981), 'Accepted'),
        const SizedBox(width: 16),
        _buildLegendItem(const Color(0xFFEF4444), 'Rejected'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildTableView() {
    // Filter bookings for selected date, status and search query
    final filteredBookings = _bookings.where((booking) {
      // First filter by date
      final start = booking['start'] as DateTime;
      final end = booking['end'] as DateTime;
      final isDateMatch = _selectedDate.isAtSameMomentAs(start) ||
          (_selectedDate.isAfter(start) && _selectedDate.isBefore(end)) ||
          _selectedDate.isAtSameMomentAs(end);
      
      // Then filter by status
      final isStatusMatch = _selectedStatus == 'All Statuses' || 
          booking['status'] == _selectedStatus;

      // Then filter by search query
      final property = (booking['property'] as String).toLowerCase();
      final customer = (booking['customer'] as String).toLowerCase();
      final searchTerm = _searchQuery.toLowerCase();
      final isSearchMatch = _searchQuery.isEmpty ||
          property.contains(searchTerm) ||
          customer.contains(searchTerm);

      // All conditions must match
      return isDateMatch && isStatusMatch && isSearchMatch;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: filteredBookings.isEmpty
          ? const Center(child: Text('No bookings for this date'))
          : Column(
              children: filteredBookings.map((booking) => _buildReservationCard(booking)).toList(),
            ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['property'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking['customer'],
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('dd-MM-yyyy').format(booking['start'])} - ${DateFormat('dd-MM-yyyy').format(booking['end'])}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking['price'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF649EFF),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: booking['status'] == 'Accepted'
                        ? const Color(0xFFD1FAE5)
                        : booking['status'] == 'Pending'
                            ? const Color(0xFFFFF9C4)
                            : const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'],
                    style: TextStyle(
                      color: booking['status'] == 'Accepted'
                          ? const Color(0xFF065F46)
                          : booking['status'] == 'Pending'
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFEF4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  UserRole? get _drawerRole => userRoleFromString(_currentUserRole);

  List<DrawerMenuItem> get _drawerItems {
    if (_drawerRole == null) return [];
    return drawerMenuItemsForRole(_drawerRole!);
  }

  void _handleBottomNavTap(int index) {
    final navRole = _drawerRole;
    if (navRole == null) return;

    if (index == 4) {
      // More button handled by SharedBottomNavigationBar
      return;
    }

    if (index == 0) {
      final route = navRole == UserRole.admin ? '/admin' : '/moderator';
      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.pushNamedAndRemoveUntil(route, (route) => false);
      } else {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(route, (route) => false);
      }
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushNamed('/manage-services');
      return;
    }

    if (index == 2) {
      if (_selectedIndex != 2) {
        setState(() => _selectedIndex = 2);
      }
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushNamed('/profile');
    }
  }

  Widget _buildDrawer() {
    if (_drawerRole == null) return const Drawer();
    return MoreMenuDrawer(
      role: _drawerRole!,
      onItemSelected: _handleMenuSelection,
    );
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      final userGroup = _currentUserRole;
      if (userGroup == 'admin') {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
      } else if (userGroup == 'moderator') {
        Navigator.of(context).pushNamedAndRemoveUntil('/moderator', (route) => false);
      }
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
      // Already on bookings page
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
