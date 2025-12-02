import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/session.dart';
import '../shared/bottom_navigation_bar.dart';
import '../shared/navigation_menu.dart' as nav;
import '../app.dart';
import '../api.dart' as api;
import 'admin_dashboard.dart';

class AdminNotifications extends StatefulWidget {
  const AdminNotifications({super.key});

  @override
  State<AdminNotifications> createState() => _AdminNotificationsState();
}

class _AdminNotificationsState extends State<AdminNotifications> {
  int _selectedIndex = -1;
  String _selectedFilter = 'All';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<void> _notificationInit;
  bool _isLoading = true;
  List<Map<String, dynamic>> allNotifications = [];

  @override
  void initState() {
    super.initState();
    _notificationInit = NotificationService().initialize();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await api.fetchNotifications();
      setState(() {
        allNotifications = notifications.map((n) => n as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading notifications: $error');
      setState(() {
        _isLoading = false;
        allNotifications = [];
      });
    }
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (_selectedFilter == 'All') {
      return allNotifications;
    } else if (_selectedFilter == 'Unread') {
      return allNotifications.where((n) => !(n['isRead'] ?? false)).toList();
    }
    return allNotifications.where((n) => n['type'] == _selectedFilter).toList();
  }

  int get unreadCount {
    return allNotifications.where((n) => !(n['isRead'] ?? false)).length;
  }

  Future<void> _markAsRead(int id) async {
    try {
      final success = await api.markNotificationAsRead(id);
      if (success) {
        setState(() {
          final notification = allNotifications.firstWhere((n) => n['id'] == id);
          notification['isRead'] = true;
        });
      }
    } catch (error) {
      print('Error marking notification as read: $error');
      setState(() {
        final notification = allNotifications.firstWhere((n) => n['id'] == id);
        notification['isRead'] = true;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await api.markAllNotificationsAsRead();
      if (success) {
        setState(() {
          for (var notification in allNotifications) {
            notification['isRead'] = true;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Color(0xFF468FAF),
            ),
          );
        }
      }
    } catch (error) {
      print('Error marking all notifications as read: $error');
      setState(() {
        for (var notification in allNotifications) {
          notification['isRead'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Color(0xFF468FAF),
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final success = await api.deleteNotification(id);
      if (success) {
        setState(() {
          allNotifications.removeWhere((n) => n['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              backgroundColor: Color(0xFF468FAF),
            ),
          );
        }
      }
    } catch (error) {
      print('Error deleting notification: $error');
      setState(() {
        allNotifications.removeWhere((n) => n['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Color(0xFF468FAF),
          ),
        );
      }
    }
  }

  void _pickupSuggestion(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF0077B6),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pick Up Suggestion?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to handle this customer request for ${notification['propertyName']}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          notification['canPickup'] = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Suggestion picked up successfully!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
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
                        'Confirm',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      Navigator.of(context).pushReplacementNamed('/manage-services');
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushReplacementNamed('/manage-booking');
      return;
    }
    if (index == 0) {
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (route) => false);
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushReplacementNamed('/profile');
      return;
    }
    if (label == 'User Management') {
      // Navigate to user management page with admin role
      Navigator.of(context).pushReplacementNamed('/user-management', arguments: AppRole.admin);
      return;
    }
    if (label == 'Properties') {
      Navigator.of(context).pushReplacementNamed('/manage-services');
      return;
    }
    if (label == 'Bookings') {
      Navigator.of(context).pushReplacementNamed('/manage-booking');
      return;
    }
    if (label == 'AuditTrails') {
      Navigator.of(context).pushNamed('/admin-audit-trails');
      return;
    }
    if (label == 'BooknPayLog') {
      Navigator.of(context).pushNamed('/admin-book-and-pay');
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
      appBar: _buildAppBar(),
      endDrawer: MoreMenuDrawer(
        role: nav.UserRole.admin,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                color: const Color(0xFF649EFF),
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                child: Column(
                  children: [
                    _buildFilterSection(),
                    Expanded(
                      child: filteredNotifications.isEmpty
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmptyState(),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredNotifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                    filteredNotifications[index]);
                              },
                            ),
                    ),
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
                colors: [Color(0xFF0077B6), Color(0xFF649EFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Stay updated with customer requests and bookings',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
          onPressed: _loadNotifications,
          tooltip: 'Refresh notifications',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unreadCount Unread',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (allNotifications.isNotEmpty)
                    Text(
                      '${allNotifications.length} Total',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Mark all read'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF649EFF),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All'),
                _buildFilterChip('Unread', 'Unread'),
                _buildFilterChip('payment_received', 'Payments'),
                _buildFilterChip('room_enquiry', 'Enquiries'),
                _buildFilterChip('broadcast_suggestion', 'Broadcasts'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF649EFF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF649EFF)
              : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Dismissible(
      key: Key(notification['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: InkWell(
        onTap: () {
          if (!notification['isRead']) {
            _markAsRead(notification['id']);
          }
          _showNotificationDetails(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: notification['isRead']
                ? Colors.white
                : const Color(0xFFE7F0FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification['isRead']
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF649EFF),
              width: notification['isRead'] ? 1 : 2,
            ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationIcon(
                        notification['type'], notification['isRead']),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (!notification['isRead'])
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF649EFF),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['message'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification['time'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (notification['type'] == 'broadcast_suggestion' &&
                    notification['canPickup'] == true) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pickupSuggestion(notification),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Pick Up Suggestion'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type, bool isRead) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
      case 'payment_received':
        icon = Icons.payment;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'room_enquiry':
        icon = Icons.help_outline;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'broadcast_suggestion':
        icon = Icons.campaign;
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      default:
        icon = Icons.notifications;
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: isRead ? 0.5 : 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 60,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All caught up!\nWe\'ll notify you of new customer activities.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNotificationIcon(notification['type'], false),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification['message'],
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (notification['customerName'] != null)
                    _buildDetailItem(
                        Icons.person, 'Customer', notification['customerName']),
                  if (notification['propertyName'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.home, 'Property',
                        notification['propertyName']),
                  ],
                  if (notification['amount'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                      Icons.attach_money,
                      'Amount',
                      'RM ${notification['amount'].toStringAsFixed(2)}',
                    ),
                  ],
                  if (notification['dates'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                        Icons.calendar_today, 'Dates', notification['dates']),
                  ],
                  if (notification['broadcastBy'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(Icons.person_outline, 'Broadcast By',
                        notification['broadcastBy']),
                  ],
                  if (notification['details'] != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailItem(
                        Icons.info_outline, 'Details', notification['details']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(
                  notification['time'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (notification['type'] == 'broadcast_suggestion' &&
                notification['canPickup'] == true)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickupSuggestion(notification);
                      },
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text(
                        'Pick Up Suggestion',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteNotification(notification['id']);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening details...'),
                          backgroundColor: Color(0xFF468FAF),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF649EFF)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

}
