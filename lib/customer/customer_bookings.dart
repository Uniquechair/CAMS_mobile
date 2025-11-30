import 'package:flutter/material.dart';
import 'customer_rooms.dart';
import 'customer_cart.dart';
import '../api.dart' as api;
import '../services/session.dart';
import 'dart:convert';
import 'dart:typed_data';

class CustomerBookings extends StatefulWidget {
  const CustomerBookings({super.key});

  @override
  State<CustomerBookings> createState() => _CustomerBookingsState();
}

class _CustomerBookingsState extends State<CustomerBookings> {
  int _selectedIndex = 2;

  List<Map<String, dynamic>> upcomingBookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingsData = await api.fetchReservation();
      
      List<Map<String, dynamic>> loadedBookings = [];
      for (var booking in bookingsData) {
        // Include all reservations in bookings page (including pending)
        // The cart page will filter out pending ones for its history section
        
        // Use backend field names: checkindatetime and checkoutdatetime
        String checkIn = _formatDate(booking['checkindatetime']);
        String checkOut = _formatDate(booking['checkoutdatetime']);
        int nights = _calculateNights(booking['checkindatetime'], booking['checkoutdatetime']);
        
        String? imageUrl;
        Uint8List? imageBytes;
        if (booking['propertyimage'] != null) {
          if (booking['propertyimage'] is List && (booking['propertyimage'] as List).isNotEmpty) {
            final firstImage = (booking['propertyimage'] as List)[0];
            if (firstImage != null && firstImage.toString().isNotEmpty) {
              try {
                imageBytes = base64Decode(firstImage.toString());
                imageUrl = 'base64';
                print('CustomerBookings: Successfully decoded base64 image');
              } catch (e) {
                print('CustomerBookings: Error decoding base64 image: $e');
                imageUrl = null;
              }
            }
          } else if (booking['propertyimage'] is String && (booking['propertyimage'] as String).isNotEmpty) {
            try {
              imageBytes = base64Decode(booking['propertyimage'].toString());
              imageUrl = 'base64';
              print('CustomerBookings: Successfully decoded base64 image (string format)');
            } catch (e) {
              print('CustomerBookings: Error decoding base64 image string: $e');
              imageUrl = null;
            }
          }
        }
        
        if (imageUrl == null) {
          print('CustomerBookings: No valid image found, propertyimage: ${booking['propertyimage']}');
        }

        loadedBookings.add({
          'id': booking['reservationid'].toString(),
          'propertyName': booking['propertyaddress'] ?? 'Property',
          'location': booking['nearbylocation'] ?? 'Unknown Location',
          'checkIn': checkIn,
          'checkOut': checkOut,
          'guests': booking['guestpaxno'] ?? 1,
          'nights': nights,
          'status': _mapStatus(booking['reservationstatus'] ?? 'Pending'),
          'imageUrl': imageUrl,
          'imageBytes': imageBytes,
        });
      }
      
      print('CustomerBookings: Loaded ${loadedBookings.length} bookings from API');

      if (mounted) {
        setState(() {
          upcomingBookings = loadedBookings;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('CustomerBookings: Error loading bookings: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load bookings. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        // Try to parse as DateTime first (handles ISO format with or without time)
        try {
          final dateTime = DateTime.parse(date);
          // Format as DD/MM/YYYY
          final day = dateTime.day.toString().padLeft(2, '0');
          final month = dateTime.month.toString().padLeft(2, '0');
          final year = dateTime.year.toString();
          return '$day/$month/$year';
        } catch (e) {
          // If parsing fails, try simple split
          final parts = date.split('-');
          if (parts.length == 3) {
            return '${parts[2]}/${parts[1]}/${parts[0]}';
          }
        }
      }
      // If it's already a DateTime object
      if (date is DateTime) {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        return '$day/$month/$year';
      }
      return date.toString();
    } catch (e) {
      print('Error formatting date: $date, error: $e');
      return date.toString();
    }
  }

  int _calculateNights(dynamic checkIn, dynamic checkOut) {
    try {
      if (checkIn == null || checkOut == null) return 0;
      
      DateTime? checkInDate;
      DateTime? checkOutDate;
      
      if (checkIn is DateTime) {
        checkInDate = checkIn;
      } else if (checkIn is String) {
        checkInDate = DateTime.parse(checkIn);
      } else {
        checkInDate = DateTime.parse(checkIn.toString());
      }
      
      if (checkOut is DateTime) {
        checkOutDate = checkOut;
      } else if (checkOut is String) {
        checkOutDate = DateTime.parse(checkOut);
      } else {
        checkOutDate = DateTime.parse(checkOut.toString());
      }
      
      if (checkInDate != null && checkOutDate != null) {
        return checkOutDate.difference(checkInDate).inDays;
      }
      return 0;
    } catch (e) {
      print('Error calculating nights: checkIn=$checkIn, checkOut=$checkOut, error=$e');
      return 0;
    }
  }

  String _mapStatus(String status) {
    // Map backend statuses to frontend display statuses
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      case 'rejected':
        return 'Rejected';
      case 'paid':
        return 'Paid';
      default:
        return status;
    }
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to dashboard and clear stack so no back button appears
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (index == 1) {
      Navigator.of(context).pushReplacementNamed('/customer-cart');
    } else if (index == 3) {
      Navigator.of(context).pushReplacementNamed('/profile');
    }
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingDetailsPage(booking: booking),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0077B6),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Color(0xFF64748B)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadBookings,
                    color: const Color(0xFF0077B6),
                    child: Column(
                      children: [
                        _buildSummaryCards(),
                        Expanded(
                          child: upcomingBookings.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: upcomingBookings.length,
                                  itemBuilder: (context, index) {
                                    return _buildBookingCard(upcomingBookings[index]);
                                  },
                                ),
                        ),
                      ],
                    ),
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
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your Bookings',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View your upcoming bookings',
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
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    int confirmedCount = upcomingBookings.where((b) => b['status'] == 'Confirmed').length;
    int pendingCount = upcomingBookings.where((b) => b['status'] == 'Pending').length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Upcoming',
              upcomingBookings.length.toString(),
              Icons.calendar_month,
              const Color(0xFF0077B6),
              const Color(0xFFEAF2FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Confirmed',
              confirmedCount.toString(),
              Icons.check_circle_outline,
              const Color(0xFF10B981),
              const Color(0xFFD1FAE5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Pending',
              pendingCount.toString(),
              Icons.schedule,
              const Color(0xFFF59E0B),
              const Color(0xFFFEF3C7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildPropertyImage(
                    imageUrl: booking['imageUrl'],
                    imageBytes: booking['imageBytes'],
                    height: 200,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildStatusBadge(booking['status']),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['propertyName'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        booking['location'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoColumn(
                          Icons.calendar_today,
                          'Check-in',
                          booking['checkIn'],
                        ),
                      ),
                      Expanded(
                        child: _buildInfoColumn(
                          Icons.calendar_today,
                          'Check-out',
                          booking['checkOut'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoColumn(
                          Icons.nights_stay,
                          'Duration',
                          '${booking['nights']} nights',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoColumn(
                          Icons.people,
                          'Guests',
                          '${booking['guests']} guests',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showBookingDetails(booking),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0077B6),
                        side: const BorderSide(color: Color(0xFF0077B6)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyImage({String? imageUrl, Uint8List? imageBytes, double? height}) {
    if (imageBytes != null && imageUrl == 'base64') {
      // Use Image.memory for base64 images
      return Image.memory(
        imageBytes,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 200,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
        ),
      );
    } else if (imageUrl != null && imageUrl.startsWith('http')) {
      // Use Image.network for URL images
      return Image.network(
        imageUrl,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 200,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      // Placeholder for no image
      return Container(
        height: height ?? 200,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
      );
    }
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0077B6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    switch (status) {
      case 'Confirmed':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
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
                Icons.calendar_today,
                size: 60,
                color: Color(0xFF0077B6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Upcoming Bookings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start planning your next getaway!\nBrowse available properties and make a reservation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _selectedIndex = 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Rooms page'),
                    backgroundColor: Color(0xFF468FAF),
                  ),
                );
              },
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Browse Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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

// Full-Screen Booking Details Page
class BookingDetailsPage extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsPage({super.key, required this.booking});

  Widget _buildPropertyImage({String? imageUrl, Uint8List? imageBytes, double? height}) {
    if (imageBytes != null && imageUrl == 'base64') {
      return Image.memory(
        imageBytes,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 300,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    } else if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 300,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      return Container(
        height: height ?? 300,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share booking details'),
                  backgroundColor: Color(0xFF468FAF),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Stack(
              children: [
                _buildPropertyImage(
                  imageUrl: booking['imageUrl'],
                  imageBytes: booking['imageBytes'],
                  height: 300,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildStatusBadge(booking['status']),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property Name
                  Text(
                    booking['propertyName'],
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        booking['location'],
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Booking Information Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0FF),
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
                          'Booking Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(Icons.calendar_today, 'Check-in', booking['checkIn']),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.calendar_today, 'Check-out', booking['checkOut']),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.nights_stay, 'Duration', '${booking['nights']} nights'),
                        const SizedBox(height: 16),
                        _buildDetailRow(Icons.people, 'Guests', '${booking['guests']} guests'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Help Section
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening support...'),
                          backgroundColor: Color(0xFF468FAF),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.help_outline,
                              color: Color(0xFF0077B6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Need Help?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Contact support for assistance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF0077B6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF0077B6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    switch (status) {
      case 'Confirmed':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}