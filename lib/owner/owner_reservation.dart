import 'package:flutter/material.dart';
import 'dart:ui';
import '../shared/bottom_navigation_bar.dart';
import '../shared/navigation_menu.dart';
import '../app.dart';
import '../services/session.dart';
import '../api.dart' as api;
import 'owner_property_listing.dart';
import 'owner_dashboard.dart';

class OwnerReservationPage extends StatefulWidget {
  const OwnerReservationPage({super.key});

  @override
  State<OwnerReservationPage> createState() => _OwnerReservationPageState();
}

class _OwnerReservationPageState extends State<OwnerReservationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "All Statuses";
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _reservations = [];

  final Color brandBlue = const Color(0xFF4188FF);

  final List<String> _statusOptions = const [
    "All Statuses",
    "Pending",
    "Accepted",
    "Rejected",
    "Canceled",
    "Paid",
    "Expired",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reservationsData = await api.fetchReservation();
      
      final List<Map<String, dynamic>> loadedReservations = [];
      
      for (var reservation in reservationsData) {
        final propertyName = reservation['propertyname'] ?? 
                            reservation['propertyaddress'] ?? 
                            reservation['property'] ?? 
                            'Unknown Property';
        final customerName = reservation['customername'] ?? 
                            reservation['username'] ?? 
                            reservation['name'] ?? 
                            'Unknown Customer';
        final statusRaw = (reservation['reservationstatus'] ?? 
                          reservation['status'] ?? 
                          'Pending').toString();
        final price = _parseDouble(reservation['totalprice'] ?? 
                                  reservation['price'] ?? 
                                  reservation['amount']) ?? 0.0;
        final checkIn = _formatDate(reservation['checkindatetime'] ?? 
                                   reservation['checkin'] ?? 
                                   reservation['checkIn']);
        final checkOut = _formatDate(reservation['checkoutdatetime'] ?? 
                                    reservation['checkout'] ?? 
                                    reservation['checkOut']);
        final reservationId = reservation['reservationid']?.toString() ?? '';
        final images = reservation['propertyimage'] is List 
            ? (reservation['propertyimage'] as List).cast<String>()
            : (reservation['propertyimage'] is String 
                ? (reservation['propertyimage'] as String).split(',')
                : <String>[]);

        loadedReservations.add({
          'reservationid': reservationId,
          'property': propertyName,
          'name': customerName,
          'price': price,
          'status': _normalizeStatus(statusRaw),
          'checkIn': checkIn,
          'checkOut': checkOut,
          'images': images.isNotEmpty ? images : [],
          'propertyid': reservation['propertyid']?.toString() ?? '',
          'customerid': reservation['customerid']?.toString() ?? 
                       reservation['userid']?.toString() ?? '',
        });
      }

      if (mounted) {
        setState(() {
          _reservations = loadedReservations;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('OwnerReservation: Error loading reservations: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reservations: $error';
          _isLoading = false;
        });
      }
    }
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      if (dateValue is String) {
        // Try parsing the date string
        final date = DateTime.parse(dateValue);
        return '${date.day}/${date.month}/${date.year}';
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }

  String _normalizeStatus(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('pending') || statusLower.contains('requested')) {
      return 'Pending';
    } else if (statusLower.contains('accept')) {
      return 'Accepted';
    } else if (statusLower.contains('reject')) {
      return 'Rejected';
    } else if (statusLower.contains('cancel')) {
      return 'Canceled';
    } else if (statusLower.contains('paid') || statusLower.contains('complete')) {
      return 'Paid';
    } else if (statusLower.contains('expire')) {
      return 'Expired';
    }
    return status;
  }

  List<Map<String, dynamic>> get _filteredReservations {
    return _reservations.where((res) {
      final statusMatch = _selectedStatus == "All Statuses" ||
          res["status"].toString().toLowerCase() == _selectedStatus.toLowerCase();

      final query = _searchController.text.toLowerCase();
      final searchMatch = query.isEmpty ||
          res["name"].toString().toLowerCase().contains(query) ||
          res["property"].toString().toLowerCase().contains(query) ||
          res["reservationid"].toString().toLowerCase().contains(query);

      return statusMatch && searchMatch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange.shade700;
      case "accepted":
        return Colors.green.shade700;
      case "rejected":
        return Colors.red.shade700;
      case "canceled":
        return Colors.grey.shade600;
      case "paid":
        return Colors.blue.shade700;
      case "expired":
        return Colors.black45;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      endDrawer: MoreMenuDrawer(
        role: UserRole.owner,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Bookings',
      ),

      backgroundColor: const Color(0xFFFBFCFE),

      body: Column(
        children: [
          // -----------------------------------
          // PREMIUM HEADER (updated padding)
          // -----------------------------------
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 60),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandBlue, const Color(0xFF2E5BC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: brandBlue.withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                )
              ],
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.menu, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Reservations",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Manage bookings",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------
          // FLOATING SEARCH BAR
          // -----------------------------------
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search,
                          color: Colors.grey.shade400, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search reservations...',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: brandBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () => setState(() {}),
                          style:
                              TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('Search',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // -----------------------------------
          // FILTER SECTION
          // -----------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            color: Colors.grey.shade50,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStatus,
                              items: _statusOptions
                                  .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e,
                                          style:
                                              const TextStyle(fontSize: 14))))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedStatus = v!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: brandBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() {}),
                            borderRadius: BorderRadius.circular(14),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 11),
                              child: Text('Apply',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // -----------------------------------
          // RESULTS LIST
          // -----------------------------------
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4188FF),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 56, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredReservations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  "No reservations found",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: brandBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredReservations.length,
                              itemBuilder: (context, index) {
                                final res = _filteredReservations[index];
                                return _buildPremiumCard(res);
                              },
                            ),
                          ),
          ),
        ],
      ),

      // -----------------------------------
      // BOTTOM NAVIGATION BAR
      // -----------------------------------
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: 2,
        role: UserRole.owner,
        scaffoldKey: _scaffoldKey,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  // -----------------------------------
  // PREMIUM CARD
  // -----------------------------------
  Widget _buildPremiumCard(Map<String, dynamic> res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          // top accent bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [brandBlue, const Color(0xFF2E5BC4)]),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18)),
            ),
          ),

          // card contents
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image + info row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: res["images"] != null && 
                             (res["images"] as List).isNotEmpty
                          ? Image.network(
                              'data:image/jpeg;base64,${(res["images"] as List)[0]}',
                              height: 100,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 100,
                                width: 120,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    size: 40, color: Colors.grey),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 100,
                                  width: 120,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 100,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.home,
                                  size: 40, color: Colors.grey.shade400),
                            ),
                    ),
                    const SizedBox(width: 14),

                    // TEXT PART
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(res["property"],
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2)),
                          const SizedBox(height: 4),
                          Text(res["name"],
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 10),
                          Text('RM ${res["price"]?.toStringAsFixed(2) ?? "0.00"}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: brandBlue,
                                  fontSize: 16)),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 16),

                // Dates + status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dates
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _info('Check-In', res['checkIn']),
                          _info('Check-Out', res['checkOut']),
                        ],
                      ),
                    ),

                    // Status + menu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 7, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _statusColor(res["status"])
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            res['status'],
                            style: TextStyle(
                                color: _statusColor(res["status"]),
                                fontWeight: FontWeight.w700,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: Icon(Icons.info_outline,
                              color: brandBlue, size: 20),
                          onPressed: () => _showReservationDetails(res),
                          tooltip: 'View details',
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
      ),
    );
  }

  void _showReservationDetails(Map<String, dynamic> res) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: Text(
          'Reservation Details',
          style: const TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Reservation ID', res['reservationid'] ?? 'N/A'),
              _buildDetailRow('Property', res['property'] ?? 'N/A'),
              _buildDetailRow('Customer', res['name'] ?? 'N/A'),
              _buildDetailRow('Status', res['status'] ?? 'N/A'),
              _buildDetailRow('Check-In', res['checkIn'] ?? 'N/A'),
              _buildDetailRow('Check-Out', res['checkOut'] ?? 'N/A'),
              _buildDetailRow(
                'Total Price',
                res['price'] != null ? 'RM ${res['price']?.toStringAsFixed(2)}' : 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    final displayValue = value == null || value.toString().trim().isEmpty ? 'N/A' : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayValue,
            style: const TextStyle(color: Colors.black87),
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
      Navigator.of(context).pushReplacementNamed('/owner');
      return;
    }
    if (index == 1) {
      // Properties
      Navigator.of(context).pushReplacementNamed('/owner-property-listing');
      return;
    }
    if (index == 2) {
      // Bookings/Reservations - already on this page
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.pushNamed(context, '/profile');
      return;
    }
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      Navigator.of(context).pushReplacementNamed('/owner');
      return;
    }
    if (label == 'Profile') {
      Navigator.pushNamed(context, '/profile');
      return;
    }
    if (label == 'PropertyListing' || label == 'Properties') {
      Navigator.of(context).pushReplacementNamed('/owner-property-listing');
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      // Already on reservation page
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
      await Session.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
      }
    }
  }
}