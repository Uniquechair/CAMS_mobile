import 'package:flutter/material.dart';
import '../services/session.dart';
import '../api.dart' as api;

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  State<ManageServicesPage> createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  String? _userRole;
  int? _userid;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadData();
  }

  Future<void> _loadUserRole() async {
    final role = await Session.getUserGroup();
    final userid = await Session.getUserId();
    setState(() {
      _userRole = role;
      _userid = userid;
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
      print('ManageService: Response keys: ${propertiesData.keys.toList()}');

      if (mounted) {
        setState(() {
          // Clear only if we got successful response
          _properties.clear();
          
          // Extract properties array from response
          // The backend should return: { properties: [...] } or just [...]
          List<dynamic> apiProperties = [];
          
          // Try to find the array in different keys
          for (var key in ['properties', 'data', 'result']) {
            if (propertiesData[key] != null && propertiesData[key] is List) {
              apiProperties = List<dynamic>.from(propertiesData[key]);
              print('ManageService: Found properties in key "$key"');
              break;
            }
          }
          
          if (apiProperties.isEmpty) {
            print('ManageService: No properties found in response, data structure:');
            print('   Keys: ${propertiesData.keys.toList()}');
            propertiesData.forEach((key, value) {
              print('   $key: ${value.runtimeType}');
            });
          }
          
          print('ManageService: Processing ${apiProperties.length} properties...');
          
          for (var prop in apiProperties) {
            _properties.add({
              'propertyid': prop['propertyid'],
              'name': prop['propertydescription'] ?? 'Unnamed Property',
              'location': prop['propertyaddress'] ?? 'Unknown Location',
              'price': _parseDouble(prop['normalrate']),
              'promo': _parseDouble(prop['earlybirddiscountrate']),
              'status': prop['propertystatus'] ?? 'Available',
              'modifiedBy': 'System',
              'modifiedDaysAgo': 0,
              'active': prop['propertystatus'] == 'Available',
            });
          }
          
          print('ManageService: Properties loaded: ${_properties.length}');
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
              String propertyName = log['propertydescription'] ?? 
                                   log['propertyDescription'] ?? 
                                   log['propertyname'] ?? 
                                   log['propertyName'] ?? 
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
  final List<Map<String, dynamic>> _properties = [
    {
      'name': 'Seaside Villa',
      'location': 'Miami Beach, FL',
      'price': 250,
      'promo': null,
      'status': 'Available',
      'modifiedBy': 'Admin',
      'modifiedDaysAgo': 2,
      'active': true,
    },
    {
      'name': 'Mountain Retreat',
      'location': 'Aspen, CO',
      'price': 350,
      'promo': 315,
      'status': 'Booked',
      'modifiedBy': 'Admin',
      'modifiedDaysAgo': 3,
      'active': true,
    },
  ];

  // ----------------- AUDIT TRAIL DATA -----------------
  final List<Map<String, dynamic>> _auditTrail = [
    {
      'action': 'add',
      'user': 'Admin',
      'property': 'Seaside Villa',
      'time': '2 days ago',
      'details': 'Created new property listing with base rate \$250/night.'
    },
    {
      'action': 'edit',
      'user': 'Moderator',
      'property': 'Mountain Retreat',
      'time': '1 day ago',
      'details': 'Updated promotional rate to \$315.'
    },
    {
      'action': 'delete',
      'user': 'Admin',
      'property': 'City Apartment',
      'time': '3 days ago',
      'details': 'Removed inactive listing.'
    },
  ];

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
    final locationController = TextEditingController(
        text: existingProperty != null ? existingProperty['location'] : '');
    final priceController = TextEditingController(
        text: existingProperty != null
            ? existingProperty['price'].toString()
            : '');
    final promoController = TextEditingController(
        text: existingProperty != null
            ? existingProperty['promo']?.toString() ?? ''
            : '');
    String availability =
        existingProperty != null ? existingProperty['status'] : 'Available';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    labelStyle: TextStyle(color: Color(0xFF0077B6)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF0077B6), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price per Night (\$)',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              
              try {
                if (existingProperty == null) {
                  // Add new property
                  print('ManageService: Creating new property...');
                  
                  // Note: API expects FormData for images, but for now we'll use a placeholder
                  // TODO: Implement full property creation with image upload
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Property creation requires image upload - Feature coming soon!', style: TextStyle(color: Colors.black)),
                      backgroundColor: Color(0xFF468FAF),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  
                  // For now, add to local list only
                  setState(() {
                    _properties.add({
                      'name': nameController.text,
                      'location': locationController.text,
                      'price': double.tryParse(priceController.text) ?? 0,
                      'promo': double.tryParse(promoController.text),
                      'status': availability,
                      'modifiedBy': _userRole ?? 'User',
                      'modifiedDaysAgo': 0,
                      'active': true,
                    });
                  });
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
                      ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save property: $error', style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: Text(
                existingProperty == null ? 'Create Property' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  // ----------------- DELETE PROPERTY -----------------
  void _deleteProperty(int index) async {
    final property = _properties[index];
    final propertyid = property['propertyid'];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFE7F0FF),
        title: const Text('Delete Property', style: TextStyle(color: Colors.black)),
        content: Text(
          'Are you sure you want to delete "${property['name']}"?',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077B6),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && propertyid != null) {
      try {
        print('ManageService: Deleting property $propertyid...');
        await api.deleteProperty(propertyid);
        print('ManageService: Property deleted successfully');
        
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
        if (mounted) {
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
      backgroundColor: const Color(0xFFE7F0FF),
      appBar: AppBar(
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
    );
  }

  // ---------- Property Card ----------
  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final isActive = p['status'] == 'Available';
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
                    p['name'],
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Available' : 'Booked',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text('📍 ${p['location']}'),
            const SizedBox(height: 8),
            // Pricing Section
            if (p['promo'] != null && p['promo'] > 0 && p['promo'] < p['price']) ...[
              // Has discount - show promo price, strikethrough original, and save badge
              Text(
                '\$${p['promo']}/night',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Original price - strikethrough
                  Text(
                    '\$${p['price']}/night',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Savings badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Save \$${(p['price'] - p['promo']).toStringAsFixed(0)}',
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
              // No discount - just show regular price
              Text(
                '\$${p['price']}/night',
                style: const TextStyle(
                  color: Colors.blue,
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
                    'Modified by ${p['modifiedBy']} • ${p['modifiedDaysAgo']} days ago',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: _getThemeColor()),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _showAddPropertyDialog(existingProperty: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF024F87)),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _deleteProperty(_properties.indexOf(p)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
