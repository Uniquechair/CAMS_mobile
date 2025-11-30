import 'package:flutter/material.dart';
import 'customer_rooms.dart';
import 'customer_bookings.dart';
import '../api.dart' as api;
import '../services/session.dart';
import '../services/paypal_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class CustomerCart extends StatefulWidget {
  const CustomerCart({super.key});

  @override
  State<CustomerCart> createState() => _CustomerCartState();
}

class _CustomerCartState extends State<CustomerCart> {
  int _selectedIndex = 1;
  String sortOrder = 'Latest First';
  String filterStatus = 'All Statuses';
  String dateRange = 'All Time';

  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> allBookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  bool _isDateInFuture(dynamic dateString) {
    try {
      if (dateString == null) return false;
      final date = DateTime.parse(dateString.toString());
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final dateOnly = DateTime(date.year, date.month, date.day);
      return dateOnly.isAfter(todayOnly) || dateOnly.isAtSameMomentAs(todayOnly);
    } catch (e) {
      print('Error parsing date: $dateString, error: $e');
      return false;
    }
  }

  Future<void> _loadCartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all reservations
      final allReservations = await api.fetchReservation();
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      
      List<Map<String, dynamic>> loadedCartItems = [];
      List<Map<String, dynamic>> loadedBookings = [];
      
      for (var item in allReservations) {
        // Parse dates using backend field names: checkindatetime and checkoutdatetime
        dynamic checkInDate = item['checkindatetime'];
        dynamic checkOutDate = item['checkoutdatetime'];
        
        // Parse checkout date to check if it's in the future
        DateTime? checkoutDateTime;
        try {
          if (checkOutDate != null) {
            checkoutDateTime = DateTime.parse(checkOutDate.toString());
            checkoutDateTime = DateTime(checkoutDateTime.year, checkoutDateTime.month, checkoutDateTime.day);
          }
        } catch (e) {
          print('CustomerCart: Error parsing checkout date: $checkOutDate, error: $e');
        }
        
        String checkIn = _formatDate(checkInDate);
        String checkOut = _formatDate(checkOutDate);
        int nights = _calculateNights(checkInDate, checkOutDate);
        
        // Debug logging only if dates are missing
        if (checkIn == 'N/A' || checkOut == 'N/A') {
          print('CustomerCart: Date parsing issue for reservation ${item['reservationid']}');
          print('CustomerCart: checkindatetime: ${item['checkindatetime']}');
          print('CustomerCart: checkoutdatetime: ${item['checkoutdatetime']}');
        }
        
        // Get property image
        String? imageUrl;
        Uint8List? imageBytes;
        if (item['propertyimage'] != null) {
          if (item['propertyimage'] is List && (item['propertyimage'] as List).isNotEmpty) {
            final firstImage = (item['propertyimage'] as List)[0];
            if (firstImage != null && firstImage.toString().isNotEmpty) {
              try {
                // Decode base64 image
                imageBytes = base64Decode(firstImage.toString());
                imageUrl = 'base64'; // Marker to use Image.memory
                print('CustomerCart: Successfully decoded base64 image for property ${item['propertyaddress']}');
              } catch (e) {
                print('CustomerCart: Error decoding base64 image: $e');
                imageUrl = null;
              }
            }
          } else if (item['propertyimage'] is String && (item['propertyimage'] as String).isNotEmpty) {
            // Handle case where propertyimage is a single string
            try {
              imageBytes = base64Decode(item['propertyimage'].toString());
              imageUrl = 'base64';
              print('CustomerCart: Successfully decoded base64 image (string format)');
            } catch (e) {
              print('CustomerCart: Error decoding base64 image string: $e');
              imageUrl = null;
            }
          }
        }
        
        if (imageUrl == null) {
          print('CustomerCart: No valid image found for property ${item['propertyaddress']}, propertyimage: ${item['propertyimage']}');
        }

        final status = (item['reservationstatus'] ?? 'Pending').toString().toLowerCase();
        final isPending = status == 'pending';
        final isEnquiry = status == 'enquiry';
        final isFuture = checkoutDateTime != null && (checkoutDateTime.isAfter(todayOnly) || checkoutDateTime.isAtSameMomentAs(todayOnly));

        // Cart: Pending and Enquiry reservations with future checkout dates
        if ((isPending || isEnquiry) && isFuture) {
          // Get propertyid from various possible field names
          int? propertyId;
          if (item['propertyid'] != null) {
            propertyId = item['propertyid'] is int ? item['propertyid'] : int.tryParse(item['propertyid'].toString());
          } else if (item['propertyId'] != null) {
            propertyId = item['propertyId'] is int ? item['propertyId'] : int.tryParse(item['propertyId'].toString());
          } else if (item['property_id'] != null) {
            propertyId = item['property_id'] is int ? item['property_id'] : int.tryParse(item['property_id'].toString());
          }
          
          loadedCartItems.add({
            'id': item['reservationid'].toString(),
            'propertyName': item['propertyaddress'] ?? 'Property',
            'checkIn': checkIn,
            'checkOut': checkOut,
            'expiredDate': checkOut, // Expired date is the checkout date
            'price': (item['totalprice'] ?? 0).toDouble(),
            'nights': nights,
            'status': item['reservationstatus'] ?? 'Pending',
            'imageUrl': imageUrl,
            'imageBytes': imageBytes,
            'reservationid': item['reservationid'],
            'propertyid': propertyId,
            'rawCheckIn': checkInDate,
            'rawCheckOut': checkOutDate,
          });
        } else {
          // Booking history: All past reservations (regardless of status) + non-pending future reservations
          // Reuse the same image processing logic
          String? bookingImageUrl;
          Uint8List? bookingImageBytes;
          if (item['propertyimage'] != null) {
            if (item['propertyimage'] is List && (item['propertyimage'] as List).isNotEmpty) {
              final firstImage = (item['propertyimage'] as List)[0];
              if (firstImage != null && firstImage.toString().isNotEmpty) {
                try {
                  bookingImageBytes = base64Decode(firstImage.toString());
                  bookingImageUrl = 'base64';
                } catch (e) {
                  print('CustomerCart: Error decoding base64 image for booking: $e');
                }
              }
            } else if (item['propertyimage'] is String && (item['propertyimage'] as String).isNotEmpty) {
              try {
                bookingImageBytes = base64Decode(item['propertyimage'].toString());
                bookingImageUrl = 'base64';
              } catch (e) {
                print('CustomerCart: Error decoding base64 image string for booking: $e');
              }
            }
          }
          
          loadedBookings.add({
            'id': item['reservationid'].toString(),
            'propertyName': item['propertyaddress'] ?? 'Property',
            'checkIn': checkIn,
            'checkOut': checkOut,
            'expiredDate': checkOut,
            'price': (item['totalprice'] ?? 0).toDouble(),
            'status': item['reservationstatus'] ?? 'Pending',
            'imageUrl': bookingImageUrl,
            'imageBytes': bookingImageBytes,
          });
        }
      }
      
      print('CustomerCart: Loaded ${loadedCartItems.length} cart items (pending + future checkout)');
      print('CustomerCart: Loaded ${loadedBookings.length} booking history items (past or non-pending)');

      if (mounted) {
        setState(() {
          cartItems = loadedCartItems;
          allBookings = loadedBookings;
          _isLoading = false;
        });
      }
    } catch (error) {
      print('CustomerCart: Error loading cart data: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load cart data. Please try again.';
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

  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to dashboard and clear stack so no back button appears
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } else if (index == 2) {
      Navigator.of(context).pushReplacementNamed('/customer-bookings');
    } else if (index == 3) {
      Navigator.of(context).pushReplacementNamed('/profile');
    }
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
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

  void _showPaymentDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm Payment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to proceed to payment for this reservation?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCompletePaymentDialog(item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

  String _fmtMoney(num v) => '\$${v.toStringAsFixed(2)}';

  void _showCompletePaymentDialog(Map<String, dynamic> item) {
    final String propertyName = item['propertyName'] ?? 'Property';
    final String checkIn = item['checkIn'] ?? '-';
    final String checkOut = item['checkOut'] ?? '-';
    final int guests = (item['guests'] is int) ? item['guests'] as int : 1;

    final num subtotal = (item['price'] as num);
    final num total = subtotal;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int selected = 0; 
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Complete Payment',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Select payment method and review booking details',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF334155)),
                        SizedBox(width: 8),
                        Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _PaymentMethodCard(
                      selected: selected == 0,
                      onTap: () => setState(() => selected = 0),
                      title: 'DuitNow',
                      subtitle: 'Instant bank transfer',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 10),
                    _PaymentMethodCard(
                      selected: selected == 1,
                      onTap: () => setState(() => selected = 1),
                      title: 'PayPal',
                      subtitle: 'Secure online payment',
                      icon: Icons.account_balance_outlined,
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Booking Details:', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            propertyName,
                            style: const TextStyle(
                              color: Color(0xFF0077B6),
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('$checkIn - $checkOut', style: const TextStyle(color: Color(0xFF64748B))),
                          Text('$guests guest${guests > 1 ? "s" : ""}', style: const TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _amountRow('Subtotal:', _fmtMoney(subtotal)),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          _fmtMoney(total),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0077B6)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              if (selected == 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Redirecting to DuitNow...'),
                                    backgroundColor: Color(0xFF468FAF),
                                  ),
                                );
                              } else {
                                // PayPal payment
                                _handlePayPalPayment(item);
                              }
                            },
                            icon: const Icon(Icons.credit_card, size: 18),
                            label: const Text('Pay Now', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _amountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF1F2937))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Future<void> _handlePayPalPayment(Map<String, dynamic> item) async {
    try {
      final reservationId = item['reservationid'] as int;
      final propertyId = item['propertyid'] as int? ?? 
                        item['propertyId'] as int? ?? 
                        0;
      final amount = (item['price'] as num).toDouble();
      
      if (propertyId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Property ID not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      final result = await PayPalService.showPayPalPayment(
        context: context,
        reservationId: reservationId,
        propertyId: propertyId,
        amount: amount,
        currency: 'MYR',
        propertyName: item['propertyName'] ?? 'Property',
        checkIn: item['checkIn'] ?? '-',
        checkOut: item['checkOut'] ?? '-',
      );

      if (!mounted) return;

      if (result != null && result['status'] == 'success') {
        // Payment successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload cart data
        _loadCartData();
      } else if (result != null && result['status'] == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was cancelled'),
            backgroundColor: Color(0xFF468FAF),
          ),
        );
      }
    } catch (error) {
      print('PayPal payment error: $error');
      if (!mounted) return;
      
      String errorMessage = 'Payment error occurred';
      String errorStr = error.toString().toLowerCase();
      
      if (errorStr.contains('paypal integration not available') ||
          errorStr.contains('endpoint not found') || 
          errorStr.contains('html') ||
          errorStr.contains('backend may not be configured') ||
          errorStr.contains('failed to get paypal') ||
          errorStr.contains('no order id returned') ||
          errorStr.contains('404')) {
        errorMessage = 'PayPal integration not available. Please contact support.';
      } else {
        errorMessage = 'Payment error: ${error.toString()}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirm Cancellation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to cancel this reservation?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          // Call API to cancel reservation
                          await api.updateReservationStatus(int.parse(bookingId), 'Canceled');
                          // Reload cart data
                          _loadCartData();
                          if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking cancelled successfully'),
                            backgroundColor: Color(0xFF468FAF),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to cancel booking: ${error.toString()}'),
                                backgroundColor: const Color(0xFFEF4444),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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

  List<Map<String, dynamic>> get filteredBookings {
    List<Map<String, dynamic>> filtered = List.from(allBookings);

    if (filterStatus != 'All Statuses') {
      filtered = filtered.where((b) => b['status'] == filterStatus).toList();
    }

    if (sortOrder == 'Latest First') {
      filtered = filtered.reversed.toList();
    } else if (sortOrder == 'Price: High to Low') {
      filtered.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
    } else if (sortOrder == 'Price: Low to High') {
      filtered.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
    }

    return filtered;
  }

  double get subTotal => cartItems.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());
  int get totalNights => cartItems.fold(0, (sum, item) => sum + (item['nights'] as int));

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final bottomPad = kBottomNavigationBarHeight + bottomSafe + 24;

    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
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
                          onPressed: _loadCartData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCartData,
                    color: const Color(0xFF0077B6),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: Column(
            children: [
              _buildCartSection(),
              const SizedBox(height: 24),
              _buildHistorySection(),
            ],
                      ),
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
              gradient: const LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF92BBFF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Your Cart', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Review your selections', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)), onPressed: () {}),
        IconButton(icon: const Icon(Icons.logout, color: Color(0xFF64748B)), onPressed: _handleLogout),
      ],
    );
  }

  Widget _buildCartSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SizedBox(width: 8),
              Text('Your Cart', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          if (cartItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: const [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Color(0xFF94A3B8)),
                    SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add properties to your cart to get started',
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
          Column(children: cartItems.map((item) => _buildCartItem(item)).toList()),
          if (cartItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildCartSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildPropertyImage(
              imageUrl: item['imageUrl'],
              imageBytes: item['imageBytes'],
              height: 200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['propertyName'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Arrival: ${item['checkIn']}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'Departure: ${item['checkOut']}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_today, 'Expired Date: ${item['expiredDate']}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status:  ', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    _buildStatusBadge(item['status']),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        '${item['nights'] ?? 1} night${((item['nights'] ?? 1) as int) > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${(item['price'] as num).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (item['status']?.toString().toLowerCase() == 'enquiry')
                        ? null
                        : () => _showPaymentDialog(item),
                    icon: const Icon(Icons.credit_card, size: 18),
                    label: Text(
                      (item['status']?.toString().toLowerCase() == 'enquiry')
                          ? 'Waiting for Approval'
                          : 'Proceed to Payment',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: (item['status']?.toString().toLowerCase() == 'enquiry')
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0077B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      shadowColor: const Color(0x33211C0B),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _showCancelDialog(item['id']),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel booking'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// helper method for displaying property image correctly
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0077B6)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cart Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0077B6))),
          const SizedBox(height: 20),
          _buildSummaryRow('Total Properties:', '${cartItems.length}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Total Nights:', '$totalNights'),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal:', '\$${subTotal.toStringAsFixed(2)}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Text('\$${subTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SizedBox(width: 8),
              Text('Booking History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          ...filteredBookings.map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildDropdown('Sort By:', Icons.sort, sortOrder,
              ['Latest First', 'Oldest First', 'Price: High to Low', 'Price: Low to High'],
              (value) => setState(() => sortOrder = value!)),
          const SizedBox(height: 16),
          _buildDropdown('Filter By Status:', Icons.filter_list, filterStatus,
              ['All Statuses', 'Pending', 'Enquiry', 'Canceled', 'Rejected', 'Paid', 'Accepted'],
              (value) => setState(() => filterStatus = value!)),
          const SizedBox(height: 16),
          _buildDropdown('Date Range:', Icons.calendar_today, dateRange,
              ['All Time', 'Last 30 Days', 'Last 90 Days', 'This Year'],
              (value) => setState(() => dateRange = value!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, String value, List<String> items, Function(String?) onChanged) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0077B6)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: Container(),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
                child: _buildPropertyImage(
                  imageUrl: item['imageUrl'],
                  imageBytes: item['imageBytes'],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['propertyName'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.calendar_today, 'Check-in: ${item['checkIn']}'),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.calendar_today, 'Check-out: ${item['checkOut']}'),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.calendar_today, 'Expired Date: ${item['expiredDate']}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Status:  ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    _buildStatusBadge(item['status']),
                  ],
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
      case 'Accepted':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'Enquiry':
        color = const Color(0xFF0077B6);
        bgColor = const Color(0xFFE7F0FF);
        break;
      case 'Canceled':
      case 'Rejected':
        color = const Color(0xFFEF4444);
        bgColor = const Color(0xFFFEE2E2);
        break;
      case 'Paid':
        color = const Color(0xFF8B5CF6);
        bgColor = const Color(0xFFEDE9FE);
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
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
              Icon(icon, color: isSelected ? const Color(0xFF92BBFF) : const Color(0xFF94A3B8), size: 24),
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

class _PaymentMethodCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final IconData icon;

  const _PaymentMethodCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF0077B6) : const Color(0xFFE2E8F0);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF0077B6) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0077B6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF0077B6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
