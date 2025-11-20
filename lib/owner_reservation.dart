import 'package:flutter/material.dart';
import 'dart:ui';
import 'shared/bottom_navigation_bar.dart';
import 'shared/navigation_menu.dart';
import 'app.dart';

class OwnerReservationPage extends StatefulWidget {
  const OwnerReservationPage({super.key});

  @override
  State<OwnerReservationPage> createState() => _OwnerReservationPageState();
}

class _OwnerReservationPageState extends State<OwnerReservationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "All Statuses";

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

  final List<Map<String, dynamic>> _reservations = [];

  List<Map<String, dynamic>> get _filteredReservations {
    return _reservations.where((res) {
      final statusMatch = _selectedStatus == "All Statuses" ||
          res["status"].toLowerCase() == _selectedStatus.toLowerCase();

      final searchMatch = _searchController.text.isEmpty ||
          res["name"]
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

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

      // LEFT DRAWER
      drawer: MoreMenuDrawer(
        role: UserRole.owner,
        onItemSelected: (value) {
          Navigator.pop(context);
          if (value == "Reservation") {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OwnerReservationPage()));
          }
        },
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
            child: _filteredReservations.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredReservations.length,
                    itemBuilder: (context, index) {
                      final res = _filteredReservations[index];
                      return _buildPremiumCard(res);
                    }),
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
        onTap: (i) {},
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
                      child: Container(
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
                          Text('RM ${res["price"]}',
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
                        Icon(Icons.more_vert,
                            color: Colors.grey.shade500, size: 20),
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
}
