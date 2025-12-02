import 'package:flutter/material.dart';
import '../api.dart' as api;
import 'dart:convert';
import 'dart:typed_data';
import 'pre_customer_cart.dart';
import 'pre_customer_booking.dart';

class Property {
  final String id;
  final String name;
  final String location;
  final List<String> imageUrls;
  final List<Uint8List?> imageBytes;
  final double rating;
  final int reviews;
  final int bedrooms;
  final int guests;
  final double pricePerNight;
  final List<String> amenities;
  final String description;

  Property({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrls,
    required this.imageBytes,
    required this.rating,
    required this.reviews,
    required this.bedrooms,
    required this.guests,
    required this.pricePerNight,
    required this.amenities,
    required this.description,
  });
}

class CustomerRoomsNotLogin extends StatefulWidget {
  const CustomerRoomsNotLogin({super.key});

  @override
  State<CustomerRoomsNotLogin> createState() => _CustomerRoomsNotLoginState();
}

class _CustomerRoomsNotLoginState extends State<CustomerRoomsNotLogin> {
  int _selectedIndex = 0;

  List<Property> allProperties = [];
  List<Property> filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;

  String? selectedLocation;
  DateTimeRange? selectedDateRange;
  int adults = 1;
  int children = 0;
  RangeValues priceRange = const RangeValues(0, 500);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic data = await api.fetchProduct();

      List<dynamic> rawList = [];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['products'] is List) {
          rawList = data['products'] as List<dynamic>;
        } else if (data['properties'] is List) {
          rawList = data['properties'] as List<dynamic>;
        } else if (data['product'] is List) {
          rawList = data['product'] as List<dynamic>;
        } else if (data['data'] is List) {
          rawList = data['data'] as List<dynamic>;
        }
      }

      final List<Property> loaded = [];

      for (final item in rawList) {
        if (item is! Map<String, dynamic>) continue;
        final m = item;

        final id = (m['propertyid'] ?? m['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final name =
            (m['propertyaddress'] ?? m['name'] ?? 'Property').toString();
        final location =
            (m['nearbylocation'] ?? m['location'] ?? 'Unknown Location')
                .toString();

        // Images (base64 or URLs)
        final List<String> imageUrls = [];
        final List<Uint8List?> imageBytes = [];
        final rawImages = m['propertyimage'] ?? m['images'] ?? m['image'];

        if (rawImages is List) {
          for (final img in rawImages) {
            if (img == null) continue;
            final s = img.toString();
            if (s.isEmpty) continue;
            try {
              final bytes = base64Decode(s);
              imageUrls.add('base64');
              imageBytes.add(bytes);
            } catch (_) {
              imageUrls.add(s);
              imageBytes.add(null);
            }
          }
        } else if (rawImages is String && rawImages.isNotEmpty) {
          try {
            final bytes = base64Decode(rawImages);
            imageUrls.add('base64');
            imageBytes.add(bytes);
          } catch (_) {
            imageUrls.add(rawImages);
            imageBytes.add(null);
          }
        }

        if (imageUrls.isEmpty) {
          imageUrls.add('https://via.placeholder.com/800x600?text=No+Image');
          imageBytes.add(null);
        }

        loaded.add(
          Property(
            id: id,
            name: name,
            location: location,
            imageUrls: imageUrls,
            imageBytes: imageBytes,
            rating: 4.5,
            reviews: 0,
            bedrooms:
                int.tryParse(m['propertybedtype']?.toString() ?? '1') ?? 1,
            guests:
                int.tryParse(m['propertyguestpaxno']?.toString() ?? '2') ?? 2,
            pricePerNight:
                double.tryParse(m['normalrate']?.toString() ?? '0') ?? 0,
            amenities: const ['WiFi', 'Parking'],
            description: (m['propertydescription'] ?? m['description'] ??
                    'No description available')
                .toString(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          allProperties = loaded;
          filteredProperties = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('CustomerRoomsNotLogin: Error loading properties: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load properties. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  void _refilterProperties() {
    setState(() {
      filteredProperties = allProperties.where((property) {
        final matchesPrice = property.pricePerNight >= priceRange.start &&
            property.pricePerNight <= priceRange.end;

        final matchesGuests = property.guests >= (adults + children);

        final matchesLocation = selectedLocation == null ||
            property.location
                .toLowerCase()
                .contains(selectedLocation!.toLowerCase());

        final q = _searchQuery.trim().toLowerCase();
        final matchesSearch = q.isEmpty ||
            property.name.toLowerCase().contains(q) ||
            property.location.toLowerCase().contains(q);

        return matchesPrice && matchesGuests && matchesLocation && matchesSearch;
      }).toList();
    });
  }

  void _applyFilters() {
    _refilterProperties();
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedLocation = null;
      selectedDateRange = null;
      adults = 1;
      children = 0;
      priceRange = const RangeValues(0, 500);
    });
    _refilterProperties();
    Navigator.pop(context);
  }

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CustomerCartNotLogin()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Navigate to Cart page', style: TextStyle(color: Colors.black)),
          backgroundColor: Color(0xFF468FAF),
          duration: Duration(seconds: 1),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CustomerBookingsNotLogin()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigate to Bookings page',
              style: TextStyle(color: Colors.black)),
          backgroundColor: Color(0xFF468FAF),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
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
              child: const Icon(Icons.home, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Property Booking',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Welcome, customer',
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
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(
                Icons.login,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
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
                            const Icon(Icons.error_outline,
                                size: 60, color: Color(0xFF64748B)),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style:
                                  const TextStyle(color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProperties,
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
                        onRefresh: _loadProperties,
                        color: const Color(0xFF0077B6),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Available Properties',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  '${filteredProperties.length} properties found',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...filteredProperties
                                .map((property) => _buildPropertyCard(property)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        _searchQuery = value;
                        _refilterProperties();
                      },
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Search properties...',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0077B6), Color(0xFF92BBFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyImage(Property property, {double height = 200}) {
    if (property.imageUrls.isNotEmpty &&
        property.imageUrls[0] == 'base64' &&
        property.imageBytes.isNotEmpty &&
        property.imageBytes[0] != null) {
      return Image.memory(
        property.imageBytes[0]!,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
      );
    }

    final url = property.imageUrls.isNotEmpty
        ? property.imageUrls[0]
        : 'https://via.placeholder.com/800x600?text=No+Image';

    return Image.network(
      url,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image,
            size: 80, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailNotLoginPage(property: property),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 200,
                child: _buildPropertyImage(property),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              property.rating.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${property.reviews} reviews)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPropertyFeature(
                          Icons.bed, '${property.bedrooms} bed'),
                      const SizedBox(width: 16),
                      _buildPropertyFeature(
                          Icons.people, '${property.guests} guests'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: property.amenities
                        .map((amenity) => _buildAmenityChip(amenity))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  'RM ${property.pricePerNight.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92BBFF),
                              ),
                            ),
                            const TextSpan(
                              text: ' / night',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // IMPORTANT: keep behavior – show login required dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Login Required'),
                              content: const Text(
                                  'Please login to book this property.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0077B6),
                                  ),
                                  child: const Text('Login',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF92BBFF)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String amenity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        amenity,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF0077B6),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return SafeArea(
          top: false,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
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
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedLocation,
                        decoration: InputDecoration(
                          hintText: 'Select location',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: allProperties
                            .map((p) => p.location)
                            .toSet()
                            .toList()
                            .map(
                              (loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedLocation = value;
                          });
                          _refilterProperties();
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Guests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Adults',
                                    style: TextStyle(
                                        fontSize: 14, color: Color(0xFF64748B))),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      color: const Color(0xFF92BBFF),
                                      onPressed: () {
                                        if (adults > 1) {
                                          setModalState(() => adults--);
                                        }
                                      },
                                    ),
                                    Text(
                                      adults.toString(),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      color: const Color(0xFF92BBFF),
                                      onPressed: () {
                                        setModalState(() => adults++);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Children',
                                    style: TextStyle(
                                        fontSize: 14, color: Color(0xFF64748B))),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      color: const Color(0xFF92BBFF),
                                      onPressed: () {
                                        if (children > 0) {
                                          setModalState(() => children--);
                                        }
                                      },
                                    ),
                                    Text(
                                      children.toString(),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                      color: const Color(0xFF92BBFF),
                                      onPressed: () {
                                        setModalState(() => children++);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Price Range (per night)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: priceRange,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        activeColor: const Color(0xFF92BBFF),
                        labels: RangeLabels(
                          'RM ${priceRange.start.round()}',
                          'RM ${priceRange.end.round()}',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            priceRange = values;
                          });
                          _refilterProperties();
                        },
                      ),
                      Text(
                        'RM ${priceRange.start.round()} - RM ${priceRange.end.round()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetFilters,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF92BBFF),
                            side: const BorderSide(color: Color(0xFF92BBFF)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
      },
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
                color:
                    isSelected ? const Color(0xFF92BBFF) : const Color(0xFF94A3B8),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF92BBFF)
                      : const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyDetailNotLoginPage extends StatelessWidget {
  final Property property;

  const PropertyDetailNotLoginPage({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    Widget buildImage({double height = 300}) {
      if (property.imageUrls.isNotEmpty &&
          property.imageUrls[0] == 'base64' &&
          property.imageBytes.isNotEmpty &&
          property.imageBytes[0] != null) {
        return Image.memory(
          property.imageBytes[0]!,
          fit: BoxFit.cover,
        );
      }

      final url = property.imageUrls.isNotEmpty
          ? property.imageUrls[0]
          : 'https://via.placeholder.com/800x600?text=No+Image';

      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image,
              size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0077B6),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.arrow_back, color: Color(0xFF92BBFF)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: buildImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          property.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              property.rating.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        property.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    property.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: property.amenities
                        .map(
                          (amenity) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F0FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              amenity,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF0077B6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF92BBFF).withValues(alpha: 0.1),
                          const Color(0xFF6366F1).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF92BBFF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 48, color: Color(0xFF92BBFF)),
                        const SizedBox(height: 16),
                        const Text(
                          'Login Required',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please login to book this property',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


