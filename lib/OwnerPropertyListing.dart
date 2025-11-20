import 'package:flutter/material.dart';
import 'shared/bottom_navigation_bar.dart';
import 'shared/navigation_menu.dart';
import 'app.dart';

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

  final Color brandBlue = const Color(0xFF4188FF);

  // Status options for filter
  final List<String> _statusOptions = const [
    "All Statuses",
    "Active",
    "Inactive",
    "Pending",
    "Rejected",
  ];

  // Hardcoded sample properties (you can replace with API later)
  final List<Map<String, dynamic>> _properties = [
    {
      "pid": "P001",
      "name": "Santubong Homestay",
      "price": 165,
      "cluster": "Santubong",
      "status": "Active",
      "imageAsset": "assets/santubong_homestay.jpg",
    },
    {
      "pid": "P002",
      "name": "Zalema Binti Leman Homestay",
      "price": 120,
      "cluster": "Kuching City",
      "status": "Pending",
      "imageAsset": "assets/zalema_homestay.jpg",
      // you can add imageAsset later if you have one
    },
    {
      "pid": "P003",
      "name": "Riverfront Apartment",
      "price": 220,
      "cluster": "Waterfront",
      "status": "Inactive",
      "imageAsset": "assets/riverfront_apartment.jpg",
    },
    {
      "pid": "P004",
      "name": "Damai Beach Resort Room",
      "price": 310,
      "cluster": "Damai",
      "status": "Rejected",
      "imageAsset": "assets/damai_beach.jpg",
    },
  ];

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
          prop["price"].toString().toLowerCase().contains(query);

      return statusMatch && searchMatch;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "active":
        return Colors.green.shade700;
      case "inactive":
        return Colors.grey.shade600;
      case "pending":
        return Colors.orange.shade700;
      case "rejected":
        return Colors.red.shade700;
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

  void _showPropertyActions(Map<String, dynamic> prop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.apartment, color: brandBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        prop["name"],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.visibility_outlined, color: brandBlue),
                  title: const Text("View details"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack("View details for ${prop["name"]}");
                  },
                ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: brandBlue),
                  title: const Text("Edit property"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack("Edit property ${prop["name"]}");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text("Remove property"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSnack("Remove property ${prop["name"]}");
                    // later you can actually remove:
                    // setState(() => _properties.remove(prop));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      drawer: MoreMenuDrawer(
        role: UserRole.owner,
        onItemSelected: (value) {
          Navigator.pop(context);
          // Wire drawer nav later if needed
        },
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
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
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
            child: _filteredProperties.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProperties.length,
                    itemBuilder: (context, index) {
                      final prop = _filteredProperties[index];
                      return _buildPropertyCard(prop);
                    },
                  ),
          ),
        ],
      ),

      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: 1,
        role: UserRole.owner,
        scaffoldKey: _scaffoldKey,
        onTap: (i) {
          // Wire navigation later
        },
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
                    // IMAGE (asset if available, else placeholder)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: prop["imageAsset"] != null
                          ? Image.asset(
                              prop["imageAsset"],
                              height: 90,
                              width: 110,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      Container(
                                height: 90,
                                width: 110,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    size: 36, color: Colors.grey),
                              ),
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
                          const SizedBox(height: 8),
                          Text(
                            'RM ${prop["price"]}',
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
                      icon: Icon(Icons.more_vert,
                          color: Colors.grey.shade500, size: 20),
                      onPressed: () => _showPropertyActions(prop),
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
}
