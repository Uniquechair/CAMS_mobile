import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/session.dart';
import '../api.dart' as api;
import '../shared/bottom_navigation_bar.dart';
import '../shared/navigation_menu.dart' as nav;
import '../app.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  String? _userRole;
  int? _userid;
  String? _username;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1; // Properties page
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadData();
  }

  Future<void> _loadUserRole() async {
    final role = await Session.getUserGroup();
    final userid = await Session.getUserId();
    final username = await Session.getUsername();
    setState(() {
      _userRole = role;
      _userid = userid;
      _username = username;
    });
  }

// link the data with the api
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('ManageService: Loading data...');
    
    final userid = await Session.getUserId();
    if (userid == null) {
      print('ManageService: No userid found, keeping current data');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Try to fetch properties from API
    try {
      print('ManageService: Fetching properties from API...');
      final propertiesData = await api.fetchPropertiesListingTable();
      print('ManageService: Properties response: $propertiesData');
      print('ManageService: Response type: ${propertiesData.runtimeType}');
      print('ManageService: Response keys: ${propertiesData.keys.toList()}');

      if (mounted) {
        setState(() {
          // Clear only if we got successful response
          final previousCount = _properties.length;
          _properties.clear();
          print('ManageService: Cleared $previousCount previous properties');
          
          // Extract properties array from response
          // The backend should return: { properties: [...] } or just [...]
          List<dynamic> apiProperties = [];
          
          // Try to find the array in different keys
          for (var key in ['properties', 'data', 'result']) {
            if (propertiesData[key] != null && propertiesData[key] is List) {
              apiProperties = List<dynamic>.from(propertiesData[key]);
              print('ManageService: Found ${apiProperties.length} properties in key "$key"');
              break;
            }
          }
          
          // If still empty, check all keys for lists
          if (apiProperties.isEmpty) {
            print('ManageService: No properties found in standard keys, checking all keys...');
            propertiesData.forEach((key, value) {
              print('   Checking key "$key": ${value.runtimeType}');
              if (value is List && value.isNotEmpty) {
                print('      Found list with ${value.length} items in key "$key"');
                apiProperties = List<dynamic>.from(value);
              }
            });
          }
          
          if (apiProperties.isEmpty) {
            print('ManageService: No properties found in response, full data structure:');
            print('   Full response: $propertiesData');
            propertiesData.forEach((key, value) {
              print('   $key: ${value.runtimeType}');
              if (value is List) {
                print('      List length: ${value.length}');
                if (value.isNotEmpty) {
                  print('      First item: ${value[0]}');
                }
              } else if (value is Map) {
                print('      Map keys: ${value.keys.toList()}');
              }
            });
          }
          
          print('ManageService: Processing ${apiProperties.length} properties...');
          
          for (var prop in apiProperties) {
            print('ManageService: Processing property:');
            print('   propertyid: ${prop['propertyid']}');
            print('   propertyaddress: ${prop['propertyaddress']}');
            print('   propertydescription: ${prop['propertydescription']}');
            print('   propertystatus: ${prop['propertystatus']}');
            print('   status: ${prop['status']}');
            print('   normalrate: ${prop['normalrate']}');
            print('   userid: ${prop['userid']}');
            print('   clusterid: ${prop['clusterid']}');
            print('   categoryid: ${prop['categoryid']}');
            print('   creatorusergroup: ${prop['creatorusergroup']}');
            print('   creatorusername: ${prop['creatorusername']}');
            print('   All property keys: ${prop.keys.toList()}');
            print('   Full property object: $prop');
            
            final propertyName =
                prop['propertyaddress'] ?? prop['propertydescription'] ?? 'Unnamed Property';
            final propertyLocation =
                prop['nearbylocation'] ?? prop['propertydescription'] ?? 'Unknown Location';
            final propertyDescription = prop['propertydescription'] ?? 'No description available';
            final statusRaw = (prop['propertystatus'] ?? prop['status'] ?? 'Available').toString();
            final statusLower = statusRaw.toLowerCase();
            final creatorRole =
                (prop['creatorusergroup'] ?? prop['usergroup'] ?? prop['role'] ?? 'admin').toString();
            final creatorName = prop['creatorusername'] ?? prop['username'] ?? 'Unknown';
            final bool isDisabled = statusLower.contains('disable') || statusLower.contains('inactive');

            print('ManageService: Adding property - name: $propertyName, status: $statusRaw, creatorRole: $creatorRole');

            _properties.add({
              'propertyid': prop['propertyid'],
              'name': propertyName,
              'location': propertyLocation,
              'description': propertyDescription,
              'price': _parseDouble(prop['normalrate']),
              'promo': _parseDouble(prop['earlybirddiscountrate']),
              'status': statusRaw,
              'creatorRole': creatorRole,
              'creatorName': creatorName,
              'isDisabled': isDisabled,
              'modifiedBy': creatorName,
              'modifiedDaysAgo': 0,
            });
          }
          
          print('ManageService: Properties loaded: ${_properties.length} (was $previousCount before)');
          print('ManageService: Final properties list:');
          for (var p in _properties) {
            print('   - ${p['name']} (ID: ${p['propertyid']}, Status: ${p['status']})');
          }
        });
      }
    } catch (error) {
      print('ManageService: Error fetching properties: $error');
      // Don't show error - just keep existing/hardcoded data
      if (mounted) {
        setState(() {
          _errorMessage = null; // Don't show error to user
        });
      }
    }

    // Try to fetch audit trails from API
    try {
      print('ManageService: Fetching audit trails from API...');
      final auditData = await api.auditTrails(userid);
      print('ManageService: Audit trails response type: ${auditData.runtimeType}');

      if (mounted) {
        setState(() {
          _auditTrail.clear();
          
          if (auditData is List) {
            print('ManageService: Processing ${auditData.length} audit logs...');
            // Reverse the list so newest is at top
            final reversedAuditData = auditData.reversed.toList();
            for (var log in reversedAuditData) {
              // Debug: Print the log structure to understand the API response
              print('ManageService: Audit log entry: $log');
              print('ManageService: Log keys: ${log.keys.toList()}');
              
              // Get details/description first to check for action keywords
              String details = log['action'] ?? 
                              log['details'] ?? 
                              log['description'] ?? 
                              log['message'] ?? 
                              '';
              
              // Normalize action type to lowercase and handle various formats
              String actionType = (log['actiontype'] ?? log['actionType'] ?? log['action'] ?? '').toString().toLowerCase();
              
              // Also check the details field for action keywords (e.g., "Create Reservation")
              String detailsLower = details.toLowerCase();
              
              // Map various action type formats to standard ones (add, edit, delete, unknown)
              // IMPORTANT: Check specific patterns first to avoid false matches
              
              // 1. Check for user activities that should be "unknown" (Login, Logout, Assign User Role)
              // These should use default color, not edit color
              if (detailsLower.contains('login') ||
                  detailsLower.contains('logout') ||
                  detailsLower.contains('assign user role') ||
                  actionType.contains('login') ||
                  actionType.contains('logout') ||
                  actionType == 'login' ||
                  actionType == 'logout') {
                actionType = 'unknown';
              }
              // 2. Add actions: create, insert, add (account/property)
              else if (actionType.contains('create') || 
                  actionType.contains('insert') || 
                  (actionType.contains('add') && !actionType.contains('update')) ||
                  actionType == 'c' ||
                  actionType == 'add account' ||
                  actionType == 'add property' ||
                  detailsLower.contains('create') ||
                  detailsLower.contains('insert') ||
                  detailsLower.contains('add account') ||
                  detailsLower.contains('add property') ||
                  detailsLower.contains('created') ||
                  detailsLower.contains('new reservation') ||
                  detailsLower.contains('new property')) {
                actionType = 'add';
              } 
              // 3. Delete actions: delete, remove
              else if (actionType.contains('delete') || 
                       actionType.contains('remove') || 
                       actionType == 'd' ||
                       detailsLower.contains('delete') ||
                       detailsLower.contains('remove') ||
                       detailsLower.contains('deleted') ||
                       detailsLower.contains('removed')) {
                actionType = 'delete';
              } 
              // 4. Edit actions: update, edit, modify (profile/property) - but NOT login/logout
              else if (actionType.contains('update') || 
                       actionType.contains('edit') || 
                       actionType.contains('modify') || 
                       actionType == 'u' ||
                       actionType == 'update profile' ||
                       actionType == 'update property' ||
                       actionType == 'edit property' ||
                       (detailsLower.contains('update') && !detailsLower.contains('login') && !detailsLower.contains('logout')) ||
                       (detailsLower.contains('edit') && !detailsLower.contains('login') && !detailsLower.contains('logout')) ||
                       detailsLower.contains('modify') ||
                       detailsLower.contains('updated') ||
                       (detailsLower.contains('edited') && !detailsLower.contains('login') && !detailsLower.contains('logout')) ||
                       detailsLower.contains('modified') ||
                       detailsLower.contains('change')) {
                actionType = 'edit';
              }
              // 5. Default to unknown if no clear match
              else {
                actionType = 'unknown';
              }
              
              // Get property name from various possible fields
              String propertyName = log['propertyaddress'] ??
                                   log['propertyAddress'] ??
                                   log['propertyname'] ?? 
                                   log['propertyName'] ?? 
                                   log['propertydescription'] ?? 
                                   log['propertyDescription'] ?? 
                                   log['entityname'] ?? 
                                   log['entityName'] ??
                                   log['property'] ??
                                   log['entitytype'] ?? 
                                   log['entityType'] ?? 
                                   'Property';
              
              // Get username
              String username = log['username'] ?? 
                               log['userName'] ?? 
                               log['user'] ?? 
                               log['modifiedby'] ?? 
                               log['modifiedBy'] ?? 
                               'Unknown';
              
              // If details is empty, create a default message based on action type
              if (details.isEmpty) {
                if (actionType == 'add') {
                  details = 'Created new property listing${propertyName != 'Property' ? ' for $propertyName' : ''}';
                } else if (actionType == 'edit') {
                  details = 'Updated property details${propertyName != 'Property' ? ' for $propertyName' : ''}';
                } else if (actionType == 'delete') {
                  details = 'Removed property listing${propertyName != 'Property' ? ' for $propertyName' : ''}';
                } else {
                  details = 'Property action performed';
                }
              }
              
              _auditTrail.add({
                'action': actionType,
                'user': username,
                'property': propertyName,
                'time': _formatTimestamp(log['timestamp'] ?? log['createdat'] ?? log['createdAt'] ?? log['time']),
                'details': details,
              });
              
              print('ManageService: Mapped audit log - action: $actionType, user: $username, property: $propertyName, details: $details');
              print('ManageService: Raw actiontype field: ${log['actiontype']}, Raw action field: ${log['action']}, Raw details: ${details}');
            }
          }
          
          print('ManageService: Audit logs loaded: ${_auditTrail.length}');
        });
      }
    } catch (error) {
      print('ManageService: Error fetching audit trails: $error');
      // Don't show error - just keep existing/hardcoded data
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    
    print('ManageService: Data loading complete');
    print('Total properties: ${_properties.length}');
    print('Total audit logs: ${_auditTrail.length}');
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
      return 'Just now';
    } catch (e) {
      return 'Unknown time';
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Color _getThemeColor() {
    if (_userRole == null) return const Color(0xFF649EFF);
    switch (_userRole!.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const Color(0xFF649EFF);
      case 'moderator':
        return const Color(0xFF78AAFF);
      default:
        return const Color(0xFF649EFF);
    }
  }
  // ----------------- PROPERTY DATA -----------------
  final List<Map<String, dynamic>> _properties = [];

  // ----------------- AUDIT TRAIL DATA -----------------
  final List<Map<String, dynamic>> _auditTrail = [];

  // ----------------- UI STATE -----------------
  bool isExpanded = false;
  String _auditFilterUser = 'All';

  // Helper: filter audit trail by user
  List<Map<String, dynamic>> _filteredAudit([int? take]) {
    final list = _auditTrail.where((log) {
      if (_auditFilterUser == 'All') return true;
      return (log['user'] as String) == _auditFilterUser;
    }).toList();
    if (take != null && take < list.length) return list.take(take).toList();
    return list;
  }

  // ----------------- ADD / EDIT PROPERTY -----------------
  void _showAddPropertyDialog({Map<String, dynamic>? existingProperty}) {
    final nameController = TextEditingController(
        text: existingProperty != null ? existingProperty['name'] : '');
    final priceController = TextEditingController(
        text: existingProperty != null
            ? (existingProperty['price']?.toString() ?? '')
            : '');
    final promoController = TextEditingController(
        text: existingProperty != null
            ? existingProperty['promo']?.toString() ?? ''
            : '');
    String availability =
        existingProperty != null ? existingProperty['status'] : 'Available';
    // Category dropdown - match website options
    String? selectedCategory = existingProperty != null 
        ? (existingProperty['category'] ?? 'Homestay')
        : 'Homestay';

    final ImagePicker imagePicker = ImagePicker();
    final List<Uint8List> selectedImageBytes = [];
    
    // Save the main widget context before showing dialog
    final mainWidgetContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImages() async {
              final pickedFiles = await imagePicker.pickMultiImage(
                imageQuality: 85,
              );
              if (pickedFiles.isEmpty) return;
              final bytes = await Future.wait(
                pickedFiles.map((file) => file.readAsBytes()),
              );
              setDialogState(() {
                selectedImageBytes.addAll(bytes);
                if (selectedImageBytes.length > 8) {
                  selectedImageBytes.removeRange(8, selectedImageBytes.length);
                }
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFE7F0FF),
              title: Text(
                existingProperty == null ? 'Add New Property' : 'Edit Property',
                style: const TextStyle(color: Colors.black),
              ),
              content: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    cursorColor: Color(0xFF0077B6),
                    selectionColor: Color(0xFFB3D9FF),
                    selectionHandleColor: Color(0xFF0077B6),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Property Name',
                        labelStyle: TextStyle(color: Color(0xFF0077B6)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Cluster field - read-only (cannot be filled, matches website)
                    TextField(
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Cluster (City)',
                        labelStyle: TextStyle(color: Colors.grey),
                        hintText: 'Auto-assigned',
                        disabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price per Night (RM)',
                        labelStyle: TextStyle(color: Color(0xFF0077B6)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: promoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Promotional Rate (Optional)',
                        labelStyle: TextStyle(color: Color(0xFF0077B6)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Property Photos (min 4)',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ...selectedImageBytes.asMap().entries.map(
                          (entry) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  entry.value,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -8,
                                right: -8,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedImageBytes.removeAt(entry.key);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedImageBytes.length < 8)
                          InkWell(
                            onTap: pickImages,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0077B6)),
                                color: const Color(0xFFE7F0FF),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Color(0xFF0077B6)),
                            ),
                          ),
                      ],
                    ),
                    if (selectedImageBytes.length < 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Please add at least 4 photos.',
                          style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Category dropdown - matches website options
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'Homestay', child: Text('Homestay')),
                        DropdownMenuItem(value: 'Resort', child: Text('Resort')),
                        DropdownMenuItem(value: 'Hotel', child: Text('Hotel')),
                        DropdownMenuItem(value: 'Inn', child: Text('Inn')),
                        DropdownMenuItem(value: 'Guesthouse', child: Text('Guesthouse')),
                        DropdownMenuItem(value: 'Apartment', child: Text('Apartment')),
                        DropdownMenuItem(value: 'Hostel', child: Text('Hostel')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedCategory = v;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: Color(0xFF0077B6)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                        ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: availability,
                      items: const [
                        DropdownMenuItem(value: 'Available', child: Text('Available')),
                        DropdownMenuItem(value: 'Booked', child: Text('Booked')),
                      ],
                      onChanged: (v) => availability = v!,
                      decoration: const InputDecoration(
                        labelText: 'Availability',
                        labelStyle: TextStyle(color: Color(0xFF0077B6)),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0077B6),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Close dialog first

                    try {
                      if (existingProperty == null) {
                        final propertyName = nameController.text.trim();
                        final propertyPrice =
                            double.tryParse(priceController.text.trim());

                        if (propertyName.isEmpty ||
                            propertyPrice == null ||
                            propertyPrice <= 0 ||
                            selectedCategory == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide a valid property name, price, and category.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (selectedImageBytes.length < 4) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please upload at least 4 property photos.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final username = _username ?? await Session.getUsername();
                        if (username == null) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unable to determine user account. Please log in again.',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        showDialog(
                          context: mainWidgetContext,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0077B6),
                            ),
                          ),
                        );

                        try {
                          final result = await api.createPropertyListing(
                            username: username,
                            propertyName: propertyName,
                            location: '', // Location is not used for cluster lookup anymore
                            price: propertyPrice,
                            promoPrice: double.tryParse(promoController.text.trim()),
                            imageBytes: selectedImageBytes,
                            categoryName: selectedCategory ?? 'Homestay', // Pass selected category
                          );
                          print('ManageService: Property created successfully, result: $result');
                          
                          if (mounted) {
                            Navigator.of(mainWidgetContext).pop(); // close progress
                            ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Property request submitted successfully',
                                  style: TextStyle(color: Colors.black),
                                ),
                                backgroundColor: Color(0xFFB3E5FC),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                          
                          // Add a small delay to ensure database transaction is committed
                          await Future.delayed(const Duration(milliseconds: 500));
                          
                          // Reload data to show the new property
                          await _loadData();
                          
                          print('ManageService: Data reloaded, properties count: ${_properties.length}');
                        } catch (error) {
                          if (mounted) {
                            Navigator.of(mainWidgetContext).pop();
                            ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to create property: $error',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        // Update existing property
                        final propertyid = existingProperty['propertyid'];
                        if (propertyid != null) {
                          print('ManageService: Updating property $propertyid...');

                          // Update property status via API
                          await api.updatePropertyStatus(propertyid, availability);
                          print('ManageService: Property updated successfully');

                          // Reload data
                          await _loadData();

                          if (mounted) {
                            ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Property updated successfully', style: TextStyle(color: Colors.black)),
                                backgroundColor: Color(0xFF468FAF),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      }
                    } catch (error) {
                      print('ManageService: Error saving property: $error');
                      if (mounted) {
                        try {
                          ScaffoldMessenger.of(mainWidgetContext).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save property: $error', style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        } catch (e) {
                          print('ManageService: Could not show error snackbar: $e');
                        }
                      }
                    }
                  },
                  child: Text(
                      existingProperty == null ? 'Create Property' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------- DELETE PROPERTY -----------------
  void _deleteProperty(int index) async {
    if (index < 0 || index >= _properties.length) {
      print('ManageService: Invalid property index: $index');
      return;
    }
    
    final property = _properties[index];
    final propertyid = property['propertyid'];
    
    if (propertyid == null) {
      print('ManageService: Property ID is null, cannot delete');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid property. Cannot delete.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: const Text('Delete Property', style: TextStyle(color: Colors.black)),
        content: Text(
          'Are you sure you want to delete "${property['name']}"?\n\nThis action cannot be undone.',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePropertyById(propertyid);
    }
  }

  // Helper method to delete property by ID
  Future<void> _deletePropertyById(int propertyid) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0077B6),
            ),
          ),
        );
      }

        print('ManageService: Deleting property $propertyid...');
        await api.deleteProperty(propertyid);
        print('ManageService: Property deleted successfully');
      
      // Close loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }
        
        // Reload data from server
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Property deleted successfully', style: TextStyle(color: Colors.black)),
              backgroundColor: Color(0xFF468FAF),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        print('ManageService: Error deleting property: $error');
      
      // Close loading indicator if still open
        if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          // Dialog might already be closed
        }
        
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete property: $error', style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    }
  }

  // ----------------- FULL AUDIT TRAIL (Live Filter + Search) -----------------
  Future<void> _showFullAuditTrail() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String selectedUser = _auditFilterUser;
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setModalState) {
            final logs = _auditTrail.where((log) {
              final matchesUser = selectedUser == 'All' ||
                  (log['user'] as String) == selectedUser;
              final matchesSearch = log['property']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
              return matchesUser && matchesSearch;
            }).toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    height: 4,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Full Audit Trail',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),

                  // -------- Filter & Search Bar --------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Filter:'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedUser,
                          style: const TextStyle(
                            color: Color(0xFFD6EEFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All', style: TextStyle(color: Colors.black87)),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin', style: TextStyle(color: Colors.black87)),
                            ),
                            DropdownMenuItem(
                              value: 'Moderator',
                              child: Text('Moderator', style: TextStyle(color: Colors.black87)),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedUser = v);
                            setState(() => _auditFilterUser = v);
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${logs.length} record(s)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by property name...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) =>
                          setModalState(() => searchQuery = value),
                    ),
                  ),
                  Expanded(
                    child: logs.isEmpty
                        ? const Center(child: Text('No matching records.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: logs.length,
                            itemBuilder: (context, index) =>
                                _buildAuditCard(logs[index]),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    setState(() {}); // refresh main UI after closing
  }

  // ----------------- AUDIT CARD BUILDER -----------------
  Widget _buildAuditCard(Map<String, dynamic> log) {
    // Get action type and normalize it (handle case sensitivity and whitespace)
    final actionType = (log['action']?.toString().toLowerCase().trim() ?? 'edit');
    final details = (log['details']?.toString().toLowerCase().trim() ?? '');
    
    // Determine color and icon based on action type
    final Color color;
    final IconData icon;
    
    // Use the parsed actionType directly (it's already normalized in the parsing logic)
    // Add actions: add, create, insert, add account, add property
    if (actionType == 'add') {
      color = const Color(0xFFA8D5FF); // Light blue for add
      icon = Icons.add_circle;
    } 
    // Edit actions: edit, update, modify, update profile, update property, edit property
    else if (actionType == 'edit') {
      color = const Color(0xFFB3D9FF); // Medium blue for edit
      icon = Icons.edit;
    } 
    // Delete actions: delete, remove
    else if (actionType == 'delete') {
      color = const Color(0xFFC5D9E8); // Blue-gray for delete
      icon = Icons.delete;
    } else {
      // Default/Unknown actions (Login, Logout, Assign User Role, etc.) - use default color
      // This includes actions that don't match add/edit/delete patterns
      print('ManageService: Unknown/default action type: $actionType, details: $details');
      color = const Color(0xFF89CFF0); // Default blue for unknown actions
      icon = Icons.edit; // Still show edit icon for unknown actions
    }

    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text('${log['user']} ${log['action'] == 'unknown' ? 'posted' : log['action']}ed ${log['property']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log['details']),
            const SizedBox(height: 4),
            Text(log['time'], style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // ----------------- MAIN PAGE -----------------
  @override
  Widget build(BuildContext context) {
    final previewLogs = _filteredAudit(3);
    final themeColor = _getThemeColor();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE7F0FF),
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const SizedBox(width: 0, height: 0),
        leadingWidth: 0,
        toolbarHeight: kToolbarHeight,
        title: const Text('Manage Services', style: TextStyle(color: Colors.white)),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF0077B6)),
            tooltip: 'View Full Audit Trail',
            onPressed: _showFullAuditTrail,
          ),
        ],
      ),
      endDrawer: _userRole != null
          ? MoreMenuDrawer(
              role: _getUserRoleEnum(),
              onItemSelected: _handleMenuSelection,
              onLogout: _handleLogout,
              currentPageLabel: 'Properties',
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPropertyDialog(),
        label: const Text('Add Property'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF0077B6),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0077B6),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF0077B6),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message display
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.orange.shade900),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadData,
                                color: Colors.orange.shade700,
                                tooltip: 'Retry',
                              ),
                            ],
                          ),
                        ),
                      const Text('Property Listings',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_properties.isEmpty && _errorMessage == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: const [
                                Icon(Icons.apartment, size: 64, color: Color(0xFF94A3B8)),
                                SizedBox(height: 16),
                                Text(
                                  'No properties yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap the + button below to add your first property',
                                  style: TextStyle(color: Color(0xFF94A3B8)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._properties.map((p) => _buildPropertyCard(p)).toList(),
                      const SizedBox(height: 20),

              // ---------- Collapsible Recent Activity ----------
              GestureDetector(
                onTap: () => setState(() => isExpanded = !isExpanded),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF319EFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            isExpanded
                                ? 'Hide Recent Activity'
                                : 'Show Recent Activity',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Recent Activity',
                            style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _auditFilterUser,
                          style: const TextStyle(
                            color: Color(0xFFD6EEFF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text('All', style: TextStyle(color: Colors.black87)),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin', style: TextStyle(color: Colors.black87)),
                            ),
                            DropdownMenuItem(
                              value: 'Moderator',
                              child: Text('Moderator', style: TextStyle(color: Colors.black87)),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _auditFilterUser = v ?? 'All';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track recent changes by Admins and Moderators.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    if (previewLogs.isEmpty)
                      const Text('No activity for this filter.',
                          style: TextStyle(color: Colors.black54)),
                    ...previewLogs.map((log) => _buildAuditCard(log)),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showFullAuditTrail,
                        icon: Icon(Icons.expand_circle_down_rounded, color: _getThemeColor()),
                        label: Text('View All Activity', style: TextStyle(color: _getThemeColor())),
                      ),
                    ),
                  ],
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
                      const SizedBox(height: 80), // Extra space for FloatingActionButton
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: _userRole != null
          ? SharedBottomNavigationBar(
              selectedIndex: _selectedIndex,
              onTap: _handleBottomNavTap,
              scaffoldKey: _scaffoldKey,
              role: _getUserRoleEnum(),
            )
          : null,
    );
  }

  // ---------- Property Card ----------
  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final rawStatus = (p['status'] ?? 'Available').toString();
    final normalizedStatus = rawStatus.toLowerCase();
    final bool isRejected = normalizedStatus.contains('reject');
    final bool isDisabled = normalizedStatus.contains('disable') || (p['isDisabled'] == true);
    final bool isAvailable = !isRejected;
    final String statusLabel = isRejected ? 'Rejected' : 'Available';
    final String creatorRole = (p['creatorRole'] ?? 'admin').toString().toLowerCase();
    final bool createdByAdmin = creatorRole.contains('admin');
    final bool operatorIsAdmin = _getUserRoleEnum() == nav.UserRole.admin;

    return Card(
      color: const Color(0xFFFDFFFF),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p['name'] ?? 'Untitled',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRejected ? const Color(0xFFFFE1E1) : const Color(0xFFE0F7EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: isRejected ? const Color(0xFFD92D20) : const Color(0xFF0F9D58),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isAvailable && isDisabled)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E0FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Disabled',
                      style: TextStyle(
                        color: Color(0xFF7E22CE),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text('📍 ${p['location'] ?? 'Unknown'}'),
            const SizedBox(height: 8),
            if (p['promo'] != null && p['promo'] > 0 && p['promo'] < p['price']) ...[
              Text(
                'RM ${p['promo']}/night',
                style: const TextStyle(
                  color: Color(0xFF0077B6),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'RM ${p['price']}/night',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Save RM ${(p['price'] - p['promo']).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              Text(
                'RM ${p['price']}/night',
                style: const TextStyle(
                  color: Color(0xFF0077B6),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Modified by ${p['modifiedBy'] ?? 'System'} • ${p['modifiedDaysAgo'] ?? 0} day(s) ago',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Property actions',
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF475569)),
                  onSelected: (value) => _handlePropertyMenuSelection(value, p),
                  itemBuilder: (context) => _buildPropertyMenuItems(
                    property: p,
                    isRejected: isRejected,
                    isDisabled: isDisabled,
                    createdByAdmin: createdByAdmin,
                    operatorIsAdmin: operatorIsAdmin,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildPropertyMenuItems({
    required Map<String, dynamic> property,
    required bool isRejected,
    required bool isDisabled,
    required bool createdByAdmin,
    required bool operatorIsAdmin,
  }) {
    final items = <PopupMenuEntry<String>>[
      _buildPropertyMenuItem(
        value: 'details',
        icon: Icons.visibility,
        label: 'View details',
      ),
    ];

    if (!isRejected && operatorIsAdmin) {
      items.add(
        _buildPropertyMenuItem(
          value: isDisabled ? 'enable' : 'disable',
          icon: isDisabled ? Icons.toggle_on : Icons.toggle_off,
          label: isDisabled ? 'Enable listing' : 'Disable for edit',
        ),
      );

      if (createdByAdmin && isDisabled) {
        items.add(
          _buildPropertyMenuItem(
            value: 'edit',
            icon: Icons.edit,
            label: 'Edit listing',
          ),
        );
      }
    }

    // Add delete option for admins (or moderators can delete their own properties)
    final userRole = _getUserRoleEnum();
    final canDelete = operatorIsAdmin || 
                     (userRole == nav.UserRole.moderator && !createdByAdmin);
    
    if (canDelete) {
      items.add(
        _buildPropertyMenuItem(
          value: 'delete',
          icon: Icons.delete,
          label: 'Delete property',
        ),
      );
    }

    return items;
  }

  PopupMenuItem<String> _buildPropertyMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F172A)),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _handlePropertyMenuSelection(String action, Map<String, dynamic> property) {
    switch (action) {
      case 'details':
        _showPropertyDetails(property);
        break;
      case 'disable':
        _togglePropertyAvailability(property, disable: true);
        break;
      case 'enable':
        _togglePropertyAvailability(property, disable: false);
        break;
      case 'edit':
        _showAddPropertyDialog(existingProperty: property);
        break;
      case 'delete':
        // Find the index of the property in the list
        final index = _properties.indexWhere((p) => p['propertyid'] == property['propertyid']);
        if (index != -1) {
          _deleteProperty(index);
        } else {
          // If index not found, try to delete by propertyid directly
          _deletePropertyById(property['propertyid']);
        }
        break;
    }
  }

  Future<void> _togglePropertyAvailability(Map<String, dynamic> property, {required bool disable}) async {
    final propertyid = property['propertyid'];
    if (propertyid == null) return;
    bool dialogShown = false;
    if (mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0077B6)),
        ),
      );
    }

    try {
      await api.updatePropertyStatus(propertyid, disable ? 'Disabled' : 'Available');
      if (dialogShown && mounted) {
        Navigator.of(context).pop();
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(disable ? 'Listing disabled for edit' : 'Listing enabled'),
            backgroundColor: const Color(0xFF468FAF),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (dialogShown && mounted) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update listing: $error', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPropertyDetails(Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: Text(
          property['name'] ?? 'Property Details',
          style: const TextStyle(color: Colors.black),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Location', property['location']),
              _buildDetailRow('Status', (property['status'] ?? 'Available').toString()),
              _buildDetailRow(
                'Price',
                property['price'] != null ? 'RM ${property['price']}' : '—',
              ),
              _buildDetailRow(
                'Promo',
                property['promo'] != null ? 'RM ${property['promo']}' : '—',
              ),
              _buildDetailRow('Description', property['description']),
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
    final displayValue = value == null || value.toString().trim().isEmpty ? '—' : value.toString();
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

  nav.UserRole _getUserRoleEnum() {
    if (_userRole == null) return nav.UserRole.admin;
    final normalized = _userRole!.toLowerCase().trim();
    if (normalized == 'admin' || normalized == 'administrator') {
      return nav.UserRole.admin;
    }
    if (normalized == 'moderator') {
      return nav.UserRole.moderator;
    }
    return nav.UserRole.admin; // Default to admin
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
    if (index == 0) {
      // Dashboard
      final route = _getUserRoleEnum() == nav.UserRole.admin ? '/admin' : '/moderator';
      final navigator = appNavigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(route, (route) => false);
      } else {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(route, (route) => false);
      }
      return;
    }
    if (index == 2) {
      Navigator.of(context).pushNamed('/manage-booking');
      return;
    }
    // index == 1 is Properties (current page)
    setState(() => _selectedIndex = index);
  }

  void _handleMenuSelection(String label) {
    Navigator.pop(context);
    if (label == 'Dashboard') {
      final route = _getUserRoleEnum() == nav.UserRole.admin ? '/admin' : '/moderator';
      final navigator = appNavigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(route, (route) => false);
      } else {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(route, (route) => false);
      }
      return;
    }
    if (label == 'Profile') {
      Navigator.of(context).pushNamed('/profile');
      return;
    }
    if (label == 'User Management') {
      // Navigate to user management page
      final role = _getUserRoleEnum() == nav.UserRole.admin ? AppRole.admin : AppRole.moderator;
      Navigator.of(context).pushNamed('/user-management', arguments: role);
      return;
    }
    if (label == 'PropertyListing' || label == 'Properties') {
      // Already on this page
      return;
    }
    if (label == 'Reservation' || label == 'Bookings') {
      Navigator.of(context).pushNamed('/manage-booking');
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
}
