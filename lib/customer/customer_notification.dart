import 'package:flutter/material.dart';
import 'customer_rooms.dart';
import 'customer_cart.dart';
import 'customer_bookings.dart';
import '../services/notification_service.dart';

class CustomerNotifications extends StatefulWidget {
  const CustomerNotifications({super.key});

  @override
  State<CustomerNotifications> createState() => _CustomerNotificationsState();
}

class _CustomerNotificationsState extends State<CustomerNotifications> {
  int _selectedIndex = -1;
  String _selectedFilter = 'All';
  late Future<void> _notificationInit;

  @override
  void initState() {
    super.initState();
    _notificationInit = NotificationService().initialize();
  }

  List<Map<String, dynamic>> allNotifications = [
    {
      'id': 1,
      'type': 'payment_reminder',
      'title': 'Payment Reminder',
      'message': 'Your payment for Seaside Villa is due in 2 days. Please complete your payment to confirm your booking.',
      'propertyName': 'Seaside Villa',
      'time': '2 hours ago',
      'isRead': false,
      'priority': 'high',
    },
    {
      'id': 2,
      'type': 'booking_upcoming',
      'title': 'Upcoming Booking',
      'message': 'Your stay at Mountain Retreat is coming up in 3 days. Check-in: 12/01/2025',
      'propertyName': 'Mountain Retreat',
      'time': '5 hours ago',
      'isRead': false,
      'priority': 'medium',
    },
    {
      'id': 3,
      'type': 'booking_accepted',
      'title': 'Booking Accepted',
      'message': 'Great news! Your booking request for Urban Loft has been accepted by the administrator.',
      'propertyName': 'Urban Loft',
      'time': '1 day ago',
      'isRead': true,
      'priority': 'high',
    },
    {
      'id': 4,
      'type': 'booking_rejected',
      'title': 'Booking Rejected',
      'message': 'Unfortunately, your booking request for Beach House has been rejected. The property is not available for your selected dates.',
      'propertyName': 'Beach House',
      'time': '2 days ago',
      'isRead': true,
      'priority': 'high',
    },
    {
      'id': 5,
      'type': 'room_suggestion',
      'title': 'Room Suggestion',
      'message': 'Based on your preferences, we suggest checking out Luxury Suite. It matches your search criteria perfectly!',
      'propertyName': 'Luxury Suite',
      'time': '3 days ago',
      'isRead': false,
      'priority': 'low',
    },
    {
      'id': 6,
      'type': 'payment_reminder',
      'title': 'Payment Due Soon',
      'message': 'Final reminder: Payment for City Apartment is due tomorrow. Act now to avoid cancellation.',
      'propertyName': 'City Apartment',
      'time': '4 hours ago',
      'isRead': false,
      'priority': 'high',
    },
  ];

  List<Map<String, dynamic>> get filteredNotifications {
    if (_selectedFilter == 'All') {
      return allNotifications;
    } else if (_selectedFilter == 'Unread') {
      return allNotifications.where((n) => !n['isRead']).toList();
    }
    return allNotifications.where((n) => n['type'] == _selectedFilter).toList();
  }

  int get unreadCount => allNotifications.where((n) => !n['isRead']).length;

  void _markAsRead(int id) {
    setState(() {
      final notification = allNotifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in allNotifications) {
        notification['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF468FAF),
      ),
    );
  }

  void _deleteNotification(int id) {
    setState(() {
      allNotifications.removeWhere((n) => n['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Color(0xFF468FAF),
      ),
    );
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => RoomsPage()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Rooms page'),
          backgroundColor: Color(0xFF468FAF),
        ),
      );
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerCart()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Cart page'),
          backgroundColor: Color(0xFF468FAF),
        ),
      );
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerBookings()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Bookings page'),
          backgroundColor: Color(0xFF468FAF),
        ),
      );
    }
  }

  Widget _buildDemoSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showDemoDialog,
          icon: const Icon(Icons.notifications_active, size: 20),
          label: const Text(
            'Demo Push Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0077B6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  void _showDemoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Push Notification Demo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a notification type to send',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              _buildDemoDialogButton(
                'Payment Due',
                'Your payment for Seaside Villa is due in 2 days',
                Icons.payment,
                const Color(0xFFF59E0B),
                () => _sendDemoNotification('payment_reminder'),
              ),
              const SizedBox(height: 12),
              _buildDemoDialogButton(
                'Upcoming Booking',
                'Your stay at Mountain Retreat starts in 3 days',
                Icons.event_available,
                const Color(0xFF0077B6),
                () => _sendDemoNotification('booking_upcoming'),
              ),
              const SizedBox(height: 12),
              _buildDemoDialogButton(
                'Booking Accepted',
                'Great news! Your booking has been confirmed',
                Icons.check_circle,
                const Color(0xFF10B981),
                () => _sendDemoNotification('booking_accepted'),
              ),
              const SizedBox(height: 12),
              _buildDemoDialogButton(
                'Booking Rejected',
                'Your booking request was not approved',
                Icons.cancel,
                const Color(0xFFEF4444),
                () => _sendDemoNotification('booking_rejected'),
              ),
              const SizedBox(height: 12),
              _buildDemoDialogButton(
                'Room Suggestion',
                'Check out Luxury Suite - matches your preferences',
                Icons.lightbulb,
                const Color(0xFF8B5CF6),
                () => _sendDemoNotification('room_suggestion'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoDialogButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onPressed();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _sendDemoNotification(String type) async {
    await _notificationInit;
    final notifications = {
      'payment_reminder': {
        'title': 'Payment Reminder',
        'body': 'Your payment for Seaside Villa is due in 2 days.',
        'id': 1,
      },
      'booking_upcoming': {
        'title': 'Upcoming Booking',
        'body': 'Your stay at Mountain Retreat starts in 3 days!',
        'id': 2,
      },
      'booking_accepted': {
        'title': 'Booking Accepted ✓',
        'body': 'Great news! Your booking has been confirmed.',
        'id': 3,
      },
      'booking_rejected': {
        'title': 'Booking Rejected',
        'body': 'Your booking request was not approved.',
        'id': 4,
      },
      'room_suggestion': {
        'title': 'Room Suggestion',
        'body': 'Check out Luxury Suite - it matches your preferences!',
        'id': 5,
      },
    };

    final notification = notifications[type];
    if (notification != null) {
      await NotificationService().showNotification(
        id: notification['id'] as int,
        title: notification['title'] as String,
        body: notification['body'] as String,
        payload: type,
        type: type,
      );
      
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterSection(),
            Expanded(
              child: filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(filteredNotifications[index]);
                      },
                    ),
            ),
            _buildDemoSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF92BBFF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications, color: Colors.white, size: 24),
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
                  'Stay updated with your bookings',
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
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
          onPressed: () {},
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
                    foregroundColor: const Color(0xFF92BBFF),
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
                _buildFilterChip('payment_reminder', 'Payments'),
                _buildFilterChip('booking_upcoming', 'Upcoming'),
                _buildFilterChip('booking_accepted', 'Accepted'),
                _buildFilterChip('booking_rejected', 'Rejected'),
                _buildFilterChip('room_suggestion', 'Suggestions'),
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
        selectedColor: const Color(0xFF92BBFF),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFFE2E8F0),
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
            color: notification['isRead'] ? Colors.white : const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification['isRead'] ? const Color(0xFFE2E8F0) : const Color(0xFF92BBFF),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification['type'], notification['isRead']),
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
                                color: Color(0xFF92BBFF),
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
                          if (notification['propertyName'] != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.home,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                notification['propertyName'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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
      case 'payment_reminder':
        icon = Icons.payment;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'booking_upcoming':
        icon = Icons.event_available;
        color = const Color(0xFF0077B6);
        bgColor = const Color(0xFFEAF2FF);
        break;
      case 'booking_accepted':
        icon = Icons.check_circle;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'booking_rejected':
        icon = Icons.cancel;
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'room_suggestion':
        icon = Icons.lightbulb;
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
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 60,
                color: Color(0xFF0077B6),
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
              'You\'re all caught up!\nWe\'ll notify you when there are updates.',
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
            if (notification['propertyName'] != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Color(0xFF92BBFF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Property',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            notification['propertyName'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF94A3B8)),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                          content: Text('Opening related page...'),
                          backgroundColor: Color(0xFF468FAF),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.home, 'Rooms', 0),
              _buildBottomNavItem(Icons.shopping_cart, 'Cart', 1),
              _buildBottomNavItem(Icons.calendar_today, 'Bookings', 2),
              _buildBottomNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _navigateToPage(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFF94A3B8),
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