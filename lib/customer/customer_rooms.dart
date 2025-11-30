import 'package:flutter/material.dart';
import '../services/session.dart';
import '../api.dart' as api;
import 'dart:convert';
import 'dart:typed_data';
import 'customer_cart.dart';
import 'customer_bookings.dart';
import 'customer_notification.dart';
import '../shared/navigation_menu.dart';
import '../shared/bottom_navigation_bar.dart';

// Property Model
class Property {
  final String id;
  final String name;
  final String location;
  final List<String> imageUrls;
  final List<Uint8List?> imageBytes; // Decoded base64 images
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

// Properties data are fetch from backend API
class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  List<Property> allProperties = [];
  List<Property> filteredProperties = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<String> availableLocations = [];
  
  // Filter variables
  String? selectedLocation;
  DateTimeRange? selectedDateRange;
  int adults = 1;
  int children = 0;
  RangeValues priceRange = const RangeValues(0, 500);

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call backend API to fetch properties
      final propertiesData = await api.fetchPropertiesListingTable();
      
      List<Property> loadedProperties = [];
      
      if (propertiesData['properties'] != null) {
        final propertiesList = propertiesData['properties'] as List;
        
        for (var propertyData in propertiesList) {
          // Only include available properties
          if (propertyData['propertystatus'] == 'Available') {
            // Parse property images from backend
            List<String> imageUrls = [];
            List<Uint8List?> imageBytesList = [];
            if (propertyData['propertyimage'] != null) {
              final images = propertyData['propertyimage'] as List;
              for (var base64Image in images) {
                if (base64Image != null && base64Image.toString().isNotEmpty) {
                  try {
                    // Decode base64 to bytes
                    final bytes = base64Decode(base64Image.toString());
                    imageBytesList.add(bytes);
                    imageUrls.add('base64'); // Marker for base64 image
                    print('CustomerRooms: Successfully decoded base64 image');
                  } catch (e) {
                    print('CustomerRooms: Error decoding base64 image: $e');
                    imageBytesList.add(null);
                    imageUrls.add('https://via.placeholder.com/800x600?text=No+Image');
                  }
                }
              }
            }
            
            // If no images, add a placeholder
            if (imageUrls.isEmpty) {
              imageUrls.add('https://via.placeholder.com/800x600?text=No+Image');
              imageBytesList.add(null);
            }

            // Default amenities (backend doesn't have this data)
            List<String> amenities = ['WiFi', 'Parking'];
            
            // Map backend data to Property model
            loadedProperties.add(Property(
              id: propertyData['propertyid'].toString(),
              name: propertyData['propertyaddress'] ?? 'Property',
              location: propertyData['nearbylocation'] ?? 'Unknown Location',
              imageUrls: imageUrls,
              imageBytes: imageBytesList,
              rating: 4.5, // Default rating (backend doesn't have this)
              reviews: 0, // Default reviews (backend doesn't have this)
              bedrooms: int.tryParse(propertyData['propertybedtype']?.toString() ?? '1') ?? 1,
              guests: int.tryParse(propertyData['propertyguestpaxno']?.toString() ?? '2') ?? 2,
              pricePerNight: double.tryParse(propertyData['normalrate']?.toString() ?? '0') ?? 0,
              amenities: amenities,
              description: propertyData['propertydescription'] ?? 'No description available',
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          allProperties = loadedProperties;
          filteredProperties = loadedProperties;
          // Extract unique locations from properties
          availableLocations = loadedProperties
              .map((p) => p.location)
              .where((loc) => loc.isNotEmpty && loc != 'Unknown Location')
              .toSet()
              .toList()
            ..sort();
          _isLoading = false;
        });
      }
      
      print('CustomerRooms: Loaded ${loadedProperties.length} available properties');
    } catch (error) {
      print('CustomerRooms: Error loading properties: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load properties. Please try again.';
          _isLoading = false;
        });
      }
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
      // Clear session data
      await Session.clear();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/before-login', (route) => false);
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

  void _applyFilters() {
    setState(() {
      filteredProperties = allProperties.where((property) {
        bool matchesPrice = property.pricePerNight >= priceRange.start &&
            property.pricePerNight <= priceRange.end;
        bool matchesGuests = property.guests >= (adults + children);
        bool matchesLocation = selectedLocation == null ||
            property.location.contains(selectedLocation!);
        return matchesPrice && matchesGuests && matchesLocation;
      }).toList();
    });
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      selectedLocation = null;
      selectedDateRange = null;
      adults = 1;
      children = 0;
      priceRange = const RangeValues(0, 500);
      filteredProperties = allProperties;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button on dashboard
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF92BBFF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Property Booking',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Welcome, customer',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
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
            onPressed: () {
              Navigator.of(context).pushNamed('/customer-notifications');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF64748B)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProperties,
              color: const Color(0xFF0077B6),
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
                      : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  if (filteredProperties.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: const [
                            Icon(Icons.home_outlined, size: 80, color: Color(0xFF94A3B8)),
                            SizedBox(height: 16),
                            Text(
                              'No properties available',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or check back later',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredProperties.map((property) => _buildPropertyCard(property)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SharedBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleBottomNavTap,
        scaffoldKey: _scaffoldKey,
        role: UserRole.customer,
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Search properties...',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
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
                  colors: [Color(0xFF6366F1), Color(0xFF92BBFF)],
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

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailPage(property: property),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 200,
                child: property.imageUrls.length > 1
                    ? PageView.builder(
                        itemCount: property.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              _buildPropertyImage(
                                imageUrl: property.imageUrls[index],
                                imageBytes: index < property.imageBytes.length ? property.imageBytes[index] : null,
                                height: 200,
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${index + 1}/${property.imageUrls.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : _buildPropertyImage(
                        imageUrl: property.imageUrls[0],
                        imageBytes: property.imageBytes.isNotEmpty ? property.imageBytes[0] : null,
                        height: 200,
                      ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
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
                      const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
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
                      _buildPropertyFeature(Icons.bed, '${property.bedrooms} bed'),
                      const SizedBox(width: 16),
                      _buildPropertyFeature(Icons.people, '${property.guests} guests'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: property.amenities.map((amenity) => _buildAmenityChip(amenity)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${property.pricePerNight.toStringAsFixed(0)}',
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailPage(property: property),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
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
          child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      // Placeholder for no image
      return Container(
        height: height ?? 200,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
      );
    }
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
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        amenity,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF6366F1),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
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
                      initialValue: selectedLocation,
                      decoration: InputDecoration(
                        hintText: 'Select location',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: availableLocations.isEmpty
                          ? [const DropdownMenuItem(value: null, child: Text('No locations available'))]
                          : availableLocations
                              .map((location) => DropdownMenuItem(
                                    value: location,
                                    child: Text(location),
                                  ))
                              .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedLocation = value;
                        });
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
                              const Text('Adults', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF92BBFF),
                                    onPressed: () {
                                      if (adults > 1) {
                                        setModalState(() => adults--);
                                      }
                                    },
                                  ),
                                  Text(
                                    adults.toString(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
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
                              const Text('Children', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF92BBFF),
                                    onPressed: () {
                                      if (children > 0) {
                                        setModalState(() => children--);
                                      }
                                    },
                                  ),
                                  Text(
                                    children.toString(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
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
                        '\$${priceRange.start.round()}',
                        '\$${priceRange.end.round()}',
                      ),
                      onChanged: (values) {
                        setModalState(() {
                          priceRange = values;
                        });
                      },
                    ),
                    Text(
                      '\$${priceRange.start.round()} - \$${priceRange.end.round()}',
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
        );
      },
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 0) {
      // Rooms - already on this page
      if (_selectedIndex != 0) {
        setState(() => _selectedIndex = 0);
      }
      return;
    }
    if (index == 1) {
      // Cart
      Navigator.of(context).pushNamed('/customer-cart');
      return;
    }
    if (index == 2) {
      // Bookings
      Navigator.of(context).pushNamed('/customer-bookings');
      return;
    }
    if (index == 3) {
      // Profile
      Navigator.pushNamed(context, '/profile');
      return;
    }
  }
}

// Property Detail Page
class PropertyDetailPage extends StatefulWidget {
  final Property property;

  const PropertyDetailPage({super.key, required this.property});

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  int numberOfGuests = 1;
  int _currentImageIndex = 0;
  bool _isCheckingAvailability = false;
  bool _isDateUnavailable = false;

  double calculateTotalPrice() {
    if (checkInDate == null || checkOutDate == null) return 0;
    final nights = checkOutDate!.difference(checkInDate!).inDays;
    return nights * widget.property.pricePerNight;
  }

  int calculateNights() {
    if (checkInDate == null || checkOutDate == null) return 0;
    return checkOutDate!.difference(checkInDate!).inDays;
  }

  Widget _buildPropertyImage({String? imageUrl, Uint8List? imageBytes, double? height}) {
    if (imageBytes != null && imageUrl == 'base64') {
      return Image.memory(
        imageBytes,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 200,
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
          height: height ?? 200,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      return Container(
        height: height ?? 200,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image, size: 80, color: Color(0xFF94A3B8)),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime today = DateTime.now();
    // For check-in: from today onward
    // For check-out: must be at least one day after check-in date
    final DateTime firstAllowedDate = isCheckIn 
        ? today 
        : (checkInDate ?? today).add(const Duration(days: 1));
    
    // Set initial date appropriately
    final DateTime initialDate = isCheckIn
        ? (checkInDate ?? today)
        : (checkOutDate ?? firstAllowedDate);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstAllowedDate) ? firstAllowedDate : initialDate,
      firstDate: firstAllowedDate,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF92BBFF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          // If checkout is before new check-in, reset it to check-in + 1 day
          if (checkOutDate != null && checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          checkOutDate = picked;
        }
      });
      // Check availability after date selection
      if (checkInDate != null && checkOutDate != null) {
        _checkAvailability();
      }
    }
  }

  Future<void> _checkAvailability() async {
    if (checkInDate == null) return;
    
    setState(() {
      _isCheckingAvailability = true;
      _isDateUnavailable = false;
    });

    // Format check-in date string as used in reservation API
    final checkInDateStr =
        '${checkInDate!.year}-${checkInDate!.month.toString().padLeft(2, '0')}-${checkInDate!.day.toString().padLeft(2, '0')} 00:00:00';

    try {
      final hasOverlap = await api.checkDateOverlap(
        propertyId: int.parse(widget.property.id),
        checkIn: checkInDateStr,
      );
      if (mounted) {
        setState(() {
          _isDateUnavailable = hasOverlap;
          _isCheckingAvailability = false;
        });
      }
    } catch (e) {
      // If the check fails, treat as available but log the error
      debugPrint('PropertyDetailPage: Failed to check availability: $e');
      if (mounted) {
        setState(() {
          _isDateUnavailable = false;
          _isCheckingAvailability = false;
        });
      }
    }
  }

  void _showBookingInformationDialog() {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select check-in and check-out dates'),
          backgroundColor: const Color(0xFF0077B6),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BookingInformationDialog(
        property: widget.property,
        checkInDate: checkInDate!,
        checkOutDate: checkOutDate!,
        numberOfGuests: numberOfGuests,
        totalPrice: calculateTotalPrice(),
        nights: calculateNights(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = calculateTotalPrice();
    final nights = calculateNights();

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
                child: const Icon(Icons.arrow_back, color: Color(0xFF92BBFF)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.property.imageUrls.length > 1
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.property.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildPropertyImage(
                              imageUrl: widget.property.imageUrls[index],
                              imageBytes: index < widget.property.imageBytes.length ? widget.property.imageBytes[index] : null,
                            );
                          },
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${widget.property.imageUrls.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildPropertyImage(
                      imageUrl: widget.property.imageUrls[0],
                      imageBytes: widget.property.imageBytes.isNotEmpty ? widget.property.imageBytes[0] : null,
                    ),
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
                          widget.property.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Text(
                              widget.property.rating.toString(),
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
                      const Icon(Icons.location_on, size: 20, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        widget.property.location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.property.reviews} reviews)',
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
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bed, color: Color(0xFF92BBFF)),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.property.bedrooms} Bedrooms',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: Color(0xFF92BBFF)),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.property.guests} Guests',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
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
                    widget.property.description,
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
                    children: widget.property.amenities
                        .map((amenity) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                amenity,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
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
                      border: Border.all(color: const Color(0xFF92BBFF).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book ${widget.property.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fill in your booking details below',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Check-in Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF92BBFF), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  checkInDate != null
                                      ? '${checkInDate!.day}/${checkInDate!.month}/${checkInDate!.year}'
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: checkInDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Check-out Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Color(0xFF92BBFF), size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  checkOutDate != null
                                      ? '${checkOutDate!.day}/${checkOutDate!.month}/${checkOutDate!.year}'
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: checkOutDate != null ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Number of Guests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people, color: Color(0xFF92BBFF), size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    numberOfGuests.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: const Color(0xFF92BBFF),
                                    onPressed: () {
                                      if (numberOfGuests > 1) {
                                        setState(() => numberOfGuests--);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: const Color(0xFF92BBFF),
                                    onPressed: () {
                                      if (numberOfGuests < widget.property.guests) {
                                        setState(() => numberOfGuests++);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (nights > 0) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF92BBFF)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Price per night:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      'RM ${widget.property.pricePerNight.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Number of nights:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    Text(
                                      '$nights',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Price:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      'RM ${totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92BBFF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCheckingAvailability ? null : _showBookingInformationDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isCheckingAvailability
                                  ? 'Checking...'
                                  : _isDateUnavailable
                                      ? 'Enquiry'
                                      : 'Book and Pay',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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

// Booking Information Dialog
class BookingInformationDialog extends StatefulWidget {
  final Property property;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfGuests;
  final double totalPrice;
  final int nights;

  const BookingInformationDialog({
    super.key,
    required this.property,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfGuests,
    required this.totalPrice,
    required this.nights,
  });

  @override
  State<BookingInformationDialog> createState() => _BookingInformationDialogState();
}

class _BookingInformationDialogState extends State<BookingInformationDialog> {
  final _formKey = GlobalKey<FormState>();
  String selectedTitle = 'Mr.';
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _requestsController = TextEditingController();

  bool _canEditDates = true;
  late DateTime _editableCheckIn;
  late DateTime _editableCheckOut;
  bool _isCheckingAvailability = false;
  bool _isDateUnavailable = false;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _editableCheckIn = widget.checkInDate;
    _editableCheckOut = widget.checkOutDate;
    _loadUserData();
    _checkAvailability(); // initial check for the provided dates
  }

  Future<void> _loadUserData() async {
    try {
      final userid = await Session.getUserId();
      if (userid != null) {
        final userData = await api.fetchUserData(userid);
        if (mounted) {
          setState(() {
            _firstNameController.text = userData['ufirstname']?.toString() ?? '';
            _lastNameController.text = userData['ulastname']?.toString() ?? '';
            _emailController.text = userData['uemail']?.toString() ?? '';
            _phoneController.text = userData['uphoneno']?.toString() ?? '';
            selectedTitle = userData['utitle']?.toString() ?? 'Mr.';
            _isLoadingUserData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
          });
        }
      }
    } catch (error) {
      print('Error loading user data: $error');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    super.dispose();
  }

  Widget _buildPropertyImage({String? imageUrl, Uint8List? imageBytes, double? height}) {
    if (imageBytes != null && imageUrl == 'base64') {
      return Image.memory(
        imageBytes,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 150,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
        ),
      );
    } else if (imageUrl != null && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        height: height,
        width: height != null ? double.infinity : null,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height ?? 150,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
        ),
      );
    } else {
      return Container(
        height: height ?? 150,
        width: double.infinity,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.image, size: 60, color: Color(0xFF94A3B8)),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    // For check-in: from today onward.
    // For check-out: must be at least one day after current check-in.
    final DateTime today = DateTime.now();
    final DateTime firstAllowedDate =
        isCheckIn ? today : _editableCheckIn.add(const Duration(days: 1));

    // Ensure initial date respects the minimum.
    final DateTime initialDate;
    if (isCheckIn) {
      initialDate = _editableCheckIn.isBefore(firstAllowedDate)
          ? firstAllowedDate
          : _editableCheckIn;
    } else {
      initialDate = _editableCheckOut.isBefore(firstAllowedDate)
          ? firstAllowedDate
          : _editableCheckOut;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF92BBFF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _editableCheckIn = picked;
          if (_editableCheckOut.isBefore(picked)) {
            _editableCheckOut = picked.add(const Duration(days: 1));
          }
        } else {
          _editableCheckOut = picked;
        }
      });
      await _checkAvailability();
    }
  }

  int get nights => _editableCheckOut.difference(_editableCheckIn).inDays;
  double get totalPrice => nights * widget.property.pricePerNight;

  Future<void> _checkAvailability() async {
    setState(() {
      _isCheckingAvailability = true;
      _isDateUnavailable = false;
    });

    // Format check-in date string as used in reservation API
    final checkInDateStr =
        '${_editableCheckIn.year}-${_editableCheckIn.month.toString().padLeft(2, '0')}-${_editableCheckIn.day.toString().padLeft(2, '0')} 00:00:00';

    try {
      final hasOverlap = await api.checkDateOverlap(
        propertyId: int.parse(widget.property.id),
        checkIn: checkInDateStr,
      );
      if (mounted) {
        setState(() {
          _isDateUnavailable = hasOverlap;
        });
      }
    } catch (e) {
      // If the check fails, treat as available but log the error
      debugPrint('BookingInformationDialog: Failed to check availability: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Booking Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your trip',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Dates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _canEditDates = true;
                              });
                            },
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: Color(0xFF92BBFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Check-in',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _canEditDates ? () => _selectDate(context, true) : null,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_editableCheckIn.month}/${_editableCheckIn.day}/${_editableCheckIn.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Check-out',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _canEditDates ? () => _selectDate(context, false) : null,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_editableCheckOut.month}/${_editableCheckOut.day}/${_editableCheckOut.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Guest details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Mr.', 'Mrs.', 'Ms.'].map((title) {
                          final isSelected = selectedTitle == title;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ChoiceChip(
                              label: Text(title),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    selectedTitle = title;
                                  });
                                }
                              },
                              selectedColor: const Color(0xFFEDE9FE),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFF64748B),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFFE2E8F0),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'First name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _firstNameController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last name',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _lastNameController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Invalid email';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone number',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Additional requests',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _requestsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Any special requests?',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildPropertyImage(
                                imageUrl: widget.property.imageUrls.isNotEmpty ? widget.property.imageUrls[0] : null,
                                imageBytes: widget.property.imageBytes.isNotEmpty ? widget.property.imageBytes[0] : null,
                                height: 150,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Price details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RM ${widget.property.pricePerNight.toStringAsFixed(2)} x $nights',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  'RM ${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total (MYR)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'RM ${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
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
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                      child: ElevatedButton(
                      onPressed: _isCheckingAvailability
                          ? null
                          : () async {
                        if (_formKey.currentState!.validate()) {
                          // Show loading dialog
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0077B6),
                              ),
                            ),
                          );

                          bool isEnquiryResult = false;
                          try {
                            // Validate that phone number is not empty
                            final phoneNumber = _phoneController.text.trim();
                            if (phoneNumber.isEmpty) {
                              if (mounted) Navigator.pop(context); // Close loading dialog
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a phone number'),
                                    backgroundColor: Color(0xFFEF4444),
                                  ),
                                );
                              }
                              return;
                            }

                            // Prepare reservation data - backend expects 'rc' prefix for customer details
                            // Ensure DateTime values are valid before formatting
                            try {
                              // Format dates as PostgreSQL timestamp format (YYYY-MM-DD HH:MM:SS)
                              // Backend expects timestamp, so include time component (00:00:00 for midnight)
                              final checkInDateStr = '${_editableCheckIn.year}-${_editableCheckIn.month.toString().padLeft(2, '0')}-${_editableCheckIn.day.toString().padLeft(2, '0')} 00:00:00';
                              final checkOutDateStr = '${_editableCheckOut.year}-${_editableCheckOut.month.toString().padLeft(2, '0')}-${_editableCheckOut.day.toString().padLeft(2, '0')} 00:00:00';
                              
                              print('CustomerRooms: Check-in date string: $checkInDateStr');
                              print('CustomerRooms: Check-out date string: $checkOutDateStr');
                              print('CustomerRooms: Check-in DateTime values - year: ${_editableCheckIn.year}, month: ${_editableCheckIn.month}, day: ${_editableCheckIn.day}');
                              print('CustomerRooms: Check-out DateTime values - year: ${_editableCheckOut.year}, month: ${_editableCheckOut.month}, day: ${_editableCheckOut.day}');

                              // Check if the selected check-in date overlaps an existing reservation
                              final hasOverlap = await api.checkDateOverlap(
                                propertyId: int.parse(widget.property.id),
                                checkIn: checkInDateStr,
                              );

                              // Validate dates are reasonable
                              if (_editableCheckIn.year < 2000 || _editableCheckIn.year > 2100 ||
                                  _editableCheckOut.year < 2000 || _editableCheckOut.year > 2100) {
                                throw Exception('Invalid year in date selection');
                              }
                              
                              // Determine reservation status based on date availability
                              final reservationStatus = hasOverlap ? 'Enquiry' : 'Pending';
                              
                              final reservationData = {
                                'propertyid': int.parse(widget.property.id),
                                // Use checkindatetime and checkoutdatetime to match backend response format
                                'checkindatetime': checkInDateStr,
                                'checkoutdatetime': checkOutDateStr,
                                'guestpaxno': widget.numberOfGuests,
                                'reservationstatus': reservationStatus,
                                'totalprice': totalPrice,
                                'rctitle': selectedTitle, // Title prefix (Mr., Mrs., Ms.)
                                'rcfirstname': _firstNameController.text.trim(),
                                'rclastname': _lastNameController.text.trim(),
                                'rcemail': _emailController.text.trim(),
                                'rcphoneno': phoneNumber, // Backend expects 'rcphoneno' not 'rcphonenumber'
                                'rcspecialrequests': _requestsController.text.trim().isEmpty ? null : _requestsController.text.trim(),
                              };
                              
                              print('CustomerRooms: Full reservation data: $reservationData');
                              
                              // Call API to create reservation
                              final reservationResult = await api.createReservation(reservationData);
                              
                              // If it's an enquiry, send notifications to moderator, admin, and owner
                              if (hasOverlap && reservationResult['reservationid'] != null) {
                                try {
                                  final reservationId = reservationResult['reservationid'] is int 
                                      ? reservationResult['reservationid'] 
                                      : int.parse(reservationResult['reservationid'].toString());
                                  print('CustomerRooms: Sending enquiry notification for reservation ID: $reservationId');
                                  final bookingRequestResult = await api.requestBooking(reservationId);
                                  print('CustomerRooms: Enquiry notification sent successfully. Result: $bookingRequestResult');
                                } catch (e) {
                                  // Log error but don't fail the reservation creation
                                  print('CustomerRooms: Failed to send enquiry notification: $e');
                                  print('CustomerRooms: Error details: ${e.toString()}');
                                }
                              }
                              
                              // Store hasOverlap for use in success message
                              isEnquiryResult = hasOverlap;
                              
                              // Close loading dialog on success
                              if (mounted) Navigator.pop(context);
                              
                            } catch (e) {
                              // Close loading dialog on error
                              if (mounted) Navigator.pop(context);
                              print('CustomerRooms: Error creating reservation: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                              return;
                            }

                            // Close booking dialog
                            if (mounted) Navigator.pop(context);

                            // Show success notification at the top
                            if (mounted) {
                              final overlay = Overlay.of(context);
                              late OverlayEntry overlayEntry;
                              
                              overlayEntry = OverlayEntry(
                                builder: (context) => Positioned(
                                  top: MediaQuery.of(context).padding.top + 10,
                                  left: 20,
                                  right: 20,
                                  child: Material(
                                    elevation: 6,
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF468FAF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              isEnquiryResult
                                                  ? 'Enquiry added to cart! Waiting for approval. Total: RM ${totalPrice.toStringAsFixed(2)} for $nights night(s)'
                                                  : 'Booking added to cart! Total: RM ${totalPrice.toStringAsFixed(2)} for $nights night(s)',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              overlayEntry.remove();
                                              Navigator.of(context).pushNamed('/customer-cart');
                                            },
                                            child: const Text(
                                              'View Cart',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              
                              overlay.insert(overlayEntry);
                              
                              // Remove overlay after 3 seconds
                              Future.delayed(const Duration(seconds: 3), () {
                                if (overlayEntry.mounted) {
                                  overlayEntry.remove();
                                }
                              });
                            }
                          } catch (error) {
                            // Close loading dialog
                            if (mounted) Navigator.pop(context);

                            // Show error dialog
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Row(
                                    children: const [
                                      Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 28),
                                      SizedBox(width: 12),
                                      Text('Error'),
                                    ],
                                  ),
                                  content: Text(
                                    'Failed to add booking to cart: ${error.toString()}',
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0077B6),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isCheckingAvailability
                            ? 'Checking...'
                            : 'Add to Cart',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}