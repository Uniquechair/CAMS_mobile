import 'package:flutter/material.dart';
import '../shared/bottom_navigation_bar.dart';
import '../shared/navigation_menu.dart';
import '../app.dart';
import '../services/session.dart';
import '../api.dart' as api;
import 'owner_reservation.dart';
import 'owner_dashboard.dart';

class OwnerPropertyListingPage extends StatefulWidget {
  const OwnerPropertyListingPage({super.key});

  @override
  State<OwnerPropertyListingPage> createState() =>
      _OwnerPropertyListingPageState();
}

class _OwnerPropertyListingPageState extends State<OwnerPropertyListingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "All Statuses";
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _properties = [];

  final Color brandBlue = const Color(0xFF4188FF);

  // Status options for filter
  final List<String> _statusOptions = const [
    "All Statuses",
    "Available",
    "Pending",
    "Rejected",
    "Booked",
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
      final propertiesData = await api.fetchPropertiesListingTable();
      
      List<dynamic> apiProperties = [];
      if (propertiesData['properties'] != null && propertiesData['properties'] is List) {
        apiProperties = propertiesData['properties'] as List<dynamic>;
      } else if (propertiesData['data'] != null && propertiesData['data'] is List) {
        apiProperties = propertiesData['data'] as List<dynamic>;
      }

      final List<Map<String, dynamic>> loadedProperties = [];
      
      for (var prop in apiProperties) {
        final propertyName = prop['propertyaddress'] ?? prop['propertydescription'] ?? 'Unnamed Property';
        final propertyLocation = prop['nearbylocation'] ?? prop['propertydescription'] ?? 'Unknown Location';
        final statusRaw = (prop['propertystatus'] ?? prop['status'] ?? 'Available').toString();
        final price = _parseDouble(prop['normalrate']) ?? 0.0;
        final clusterName = prop['clustername'] ?? prop['cluster'] ?? 'Unknown';
        final propertyId = prop['propertyid']?.toString() ?? '';
        final images = prop['propertyimage'] is List 
            ? (prop['propertyimage'] as List).cast<String>()
            : (prop['propertyimage'] is String 
                ? (prop['propertyimage'] as String).split(',')
                : <String>[]);

        loadedProperties.add({
          'propertyid': propertyId,
          'pid': propertyId.isNotEmpty ? 'P${propertyId.padLeft(3, '0')}' : 'P000',
          'name': propertyName,
          'price': price,
          'cluster': clusterName,
          'status': _normalizeStatus(statusRaw),
          'location': propertyLocation,
          'description': prop['propertydescription'] ?? 'No description',
          'images': images.isNotEmpty ? images : [],
          'creatorName': prop['username'] ?? prop['creatorusername'] ?? 'Unknown',
          'creatorRole': prop['usergroup'] ?? prop['creatorusergroup'] ?? 'Unknown',
        });
      }

      if (mounted) {
        setState(() {
          _properties = loadedProperties;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('OwnerPropertyListing: Error loading properties: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load properties: $error';
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

  String _normalizeStatus(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('available') || statusLower.contains('active')) {
      return 'Available';
    } else if (statusLower.contains('pending')) {
      return 'Pending';
    } else if (statusLower.contains('reject')) {
      return 'Rejected';
    } else if (statusLower.contains('book')) {
      return 'Booked';
    } else if (statusLower.contains('inactive') || statusLower.contains('disable')) {
      return 'Inactive';
    }
    return status;
  }

  List<Map<String, dynamic>> get _filteredProperties {
    return _properties.where((prop) {
      final statusMatch = _selectedStatus == "All Statuses" ||
          prop["status"].toString().toLowerCase() ==
              _selectedStatus.toLowerCase();

      final query = _searchController.text.toLowerCase();
      final searchMatch = query.isEmpty ||
          prop["name"].toString().toLowerCase().contains(query) ||
          prop["cluster"].toString().toLowerCase().contains(query) ||
          prop["pid"].toString().toLowerCase().contains(query) ||
          prop["price"].toString().toLowerCase().contains(query) ||
          prop["creatorName"].toString().toLowerCase().contains(query);

      return statusMatch && searchMatch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "available":
      case "active":
        return Colors.green.shade700;
      case "inactive":
        return Colors.grey.shade600;
      case "pending":
        return Colors.orange.shade700;
      case "rejected":
        return Colors.red.shade700;
      case "booked":
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPropertyDetails(Map<String, dynamic> prop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: Text(
          prop["name"] ?? 'Property Details',
          style: const TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Property ID', prop["pid"] ?? 'N/A'),
              _buildDetailRow('Name', prop["name"] ?? 'N/A'),
              _buildDetailRow('Cluster', prop["cluster"] ?? 'N/A'),
              _buildDetailRow('Location', prop["location"] ?? 'N/A'),
              _buildDetailRow('Status', prop["status"] ?? 'N/A'),
              _buildDetailRow(
                'Price',
                prop["price"] != null ? 'RM ${prop["price"]}' : 'N/A',
              ),
              _buildDetailRow('Description', prop["description"] ?? 'No description'),
              _buildDetailRow('Created by', prop["creatorName"] ?? 'Unknown'),
              _buildDetailRow('Creator Role', prop["creatorRole"] ?? 'Unknown'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      endDrawer: MoreMenuDrawer(
        role: UserRole.owner,
        onItemSelected: _handleMenuSelection,
        onLogout: _handleLogout,
        currentPageLabel: 'Properties',
      ),

      backgroundColor: const Color(0xFFFBFCFE),

      body: Column(
        children: [
          // HEADER
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
                        "Property Listings",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Manage your properties",
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

          // SEARCH BAR
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
                            hintText: 'Search properties...',
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
                          child: const Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // FILTER CARD
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
                  Text('Status',
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
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
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
                              child: Text(
                                'Apply Filters',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
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

          // PROPERTY LIST
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
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
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
                    : _filteredProperties.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 56, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  "No properties found",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: brandBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredProperties.length,
                              itemBuilder: (context, index) {
                                final prop = _filteredProperties[index];
                                return _buildPropertyCard(prop);
                              },
                            ),
                          ),
          ),
        ],
      ),

      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: 1,
        role: UserRole.owner,
        scaffoldKey: _scaffoldKey,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  // PROPERTY CARD + ACTION MENU
  Widget _buildPropertyCard(Map<String, dynamic> prop) {
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
          Container(
            height: 5,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [brandBlue, const Color(0xFF2E5BC4)]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PID: ${prop["pid"]}",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGE (from API if available, else placeholder)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: prop["images"] != null && 
                             (prop["images"] as List).isNotEmpty
                          ? Image.network(
                              'data:image/jpeg;base64,${(prop["images"] as List)[0]}',
                              height: 90,
                              width: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 90,
                                width: 110,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    size: 36, color: Colors.grey),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 90,
                                  width: 110,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 90,
                              width: 110,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image,
                                  size: 36, color: Colors.grey.shade400),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prop["name"],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cluster: ${prop["cluster"]}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "By: ${prop["creatorName"]} (${prop["creatorRole"]})",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'RM ${prop["price"]?.toStringAsFixed(2) ?? "0.00"}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: brandBlue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color:
                            _statusColor(prop["status"]).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        prop["status"],
                        style: TextStyle(
                          color: _statusColor(prop["status"]),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline,
                          color: brandBlue, size: 20),
                      onPressed: () => _showPropertyDetails(prop),
                      tooltip: 'View details',
                    ),
                  ],
                ),
              ],
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
      Navigator.of(context).pushReplacementNamed('/owner');
      return;
    }
    if (index == 1) {
      // Properties - already on this page
      return;
    }
    if (index == 2) {
      // Bookings/Reservations
      Navigator.of(context).pushReplacementNamed('/owner-reservation');
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
      // Already on property listing page
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      Navigator.of(context).pushReplacementNamed('/owner-reservation');
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