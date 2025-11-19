import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/session.dart';

const String API_URL = 'https://cams-backend.vercel.app';

// Register
Future<http.Response> signupUser(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    return response;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Login
Future<http.Response> loginUser(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    return response;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

Future<http.Response> checkstatus(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/checkStatus?userid=$userid'),
    );
    return response;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Logout
Future<Map<String, dynamic>> logoutUser(int userid) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/logout'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userid': userid}),
    );

    final responseData = jsonDecode(response.body);
    return responseData;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Properties Listing
Future<Map<String, dynamic>> propertiesListing(dynamic propertyData) async {
  final usergroup = await Session.getUserGroup();
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/propertiesListing'),
      body: propertyData,
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to create property');
    }

    final responseData = jsonDecode(response.body);
    return responseData;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Properties (Product)
Future<Map<String, dynamic>> fetchProduct() async {
  try {
    final response = await http.get(Uri.parse('$API_URL/product'));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch properties');
    }
    final data = jsonDecode(response.body);
    return data; 
  } catch (error) {
    print('Error fetching properties: $error');
    rethrow;
  }
}

// Fetch Properties (Dashboard)
Future<Map<String, dynamic>> fetchPropertiesListingTable() async {
  final username = await Session.getUsername();
  
  if (username == null) {
    print('API: Username not found in session, returning empty properties');
    return {'properties': []};
  }
  
  try {
    print('API: Fetching properties for username: $username');
    final response = await http.get(
      Uri.parse('$API_URL/propertiesListingTable?username=$username'),
    );

    print('API: Properties response status: ${response.statusCode}');
    print('API: Properties response body: ${response.body}');

    // Handle 404 as "no properties found"
    if (response.statusCode == 404) {
      print('API: No properties found for user (404), returning empty list');
      return {'properties': []};
    }
    
    if (response.statusCode != 200) {
      print('API: Error status ${response.statusCode}, returning empty list');
      return {'properties': []};
    }

    final data = jsonDecode(response.body);
    print('API: Properties data structure - keys: ${data.keys.toList()}');
    return data; 
  } catch (error) {
    print('Error fetching properties: $error');
    // Return empty instead of throwing
    return {'properties': []};
  }
}

// Update Property
Future<Map<String, dynamic>> updateProperty(dynamic propertyData, int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  if (propertyid == 0) {
    throw Exception('propertyid invalid');
  }
  
  try {
    final response = await http.put(
      Uri.parse('$API_URL/propertiesListing/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      body: propertyData, 
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update property');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Update property status
Future<Map<String, dynamic>> updatePropertyStatus(int propertyid, String status) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.patch(
      Uri.parse('$API_URL/updatePropertyStatus/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'propertyStatus': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update property status');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Delete Property
Future<Map<String, dynamic>> deleteProperty(int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.delete(
      Uri.parse('$API_URL/removePropertiesListing/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to delete property');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Customers
Future<Map<String, dynamic>> fetchCustomers() async {
  final userid = await Session.getUserId();
  
  try {
    print('API: Fetching customers... (userid: $userid, timestamp: ${DateTime.now().millisecondsSinceEpoch})');
    final response = await http.get(
      Uri.parse('$API_URL/users/customers?userid=$userid&_t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    print('API: Customers response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('API: Error fetching customers, returning empty');
      return {'customers': []};
    }

    final decoded = jsonDecode(response.body);
    
    // Handle both List and Map responses
    if (decoded is List) {
      print('API: Customers returned as List with ${decoded.length} items');
      return {'customers': decoded};
    } else if (decoded is Map) {
      print('API: Customers data keys: ${(decoded as Map).keys.toList()}');
      return decoded as Map<String, dynamic>;
    }
    
    return {'customers': []};
  } catch (error) {
    print('API error fetching customers: $error');
    return {'customers': []};
  }
}

// Fetch Owners
Future<Map<String, dynamic>> fetchOwners() async {
  try {
    print('API: Fetching owners... (timestamp: ${DateTime.now().millisecondsSinceEpoch})');
    final response = await http.get(
      Uri.parse('$API_URL/users/owners?_t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    print('API: Owners response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('API: Error fetching owners, returning empty');
      return {'owners': []};
    }

    final decoded = jsonDecode(response.body);
    
    // Handle both List and Map responses
    if (decoded is List) {
      print('API: Owners returned as List with ${decoded.length} items');
      return {'owners': decoded};
    } else if (decoded is Map) {
      print('API: Owners data keys: ${(decoded as Map).keys.toList()}');
      return decoded as Map<String, dynamic>;
    }
    
    return {'owners': []};
  } catch (error) {
    print('API error fetching owners: $error');
    return {'owners': []};
  }
}

// Fetch Moderators
Future<Map<String, dynamic>> fetchModerators() async {
  final userid = await Session.getUserId();
  
  try {
    print('API: Fetching moderators... (userid: $userid, timestamp: ${DateTime.now().millisecondsSinceEpoch})');
    final response = await http.get(
      Uri.parse('$API_URL/users/moderators?userid=$userid&_t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    print('API: Moderators response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('API: Error fetching moderators, returning empty');
      return {'moderators': []};
    }

    final decoded = jsonDecode(response.body);
    
    // Handle both List and Map responses
    if (decoded is List) {
      print('API: Moderators returned as List with ${decoded.length} items');
      return {'moderators': decoded};
    } else if (decoded is Map) {
      print('API: Moderators data keys: ${(decoded as Map).keys.toList()}');
      return decoded as Map<String, dynamic>;
    }
    
    return {'moderators': []};
  } catch (error) {
    print('API error fetching moderators: $error');
    return {'moderators': []};
  }
}

// Fetch Operators
Future<Map<String, dynamic>> fetchOperators() async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/operators'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch operators');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Administrator
Future<Map<String, dynamic>> fetchAdministrators() async {
  try {
    print('API: Fetching administrators... (timestamp: ${DateTime.now().millisecondsSinceEpoch})');
    final response = await http.get(
      Uri.parse('$API_URL/users/administrators?_t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    print('API: Administrators response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('API: Error fetching administrators, returning empty');
      return {'administrators': []};
    }

    final decoded = jsonDecode(response.body);
    
    // Handle both List and Map responses
    if (decoded is List) {
      print('API: Administrators returned as List with ${decoded.length} items');
      return {'administrators': decoded};
    } else if (decoded is Map) {
      print('API: Administrators data keys: ${(decoded as Map).keys.toList()}');
      return decoded as Map<String, dynamic>;
    }
    
    return {'administrators': []};
  } catch (error) {
    print('API error fetching administrators: $error');
    return {'administrators': []};
  }
}

// Create Moderator
Future<http.Response> createModerator(Map<String, dynamic> userData) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/users/createModerator'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create moderator');
    }

    return response;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Update User
Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData, int userid) async {
  try {
    final url = '$API_URL/users/updateUser/$userid';

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      try {
        final errorText = response.body;
        
        try {
          final errorData = jsonDecode(errorText) as Map<String, dynamic>;
          throw Exception(errorData['error'] ?? errorData['message'] ?? 'Failed to update user (${response.statusCode})');
        } catch (jsonError) {
          // Response is not valid JSON
          throw Exception('Server error (${response.statusCode}): ${errorText.isNotEmpty ? errorText : response.reasonPhrase}');
        }
      } catch (parseError) {
        // Error parsing response
        throw Exception('Failed to update user: ${response.statusCode} ${response.reasonPhrase}');
      }
    }

    // Attempt to parse response as JSON, if fails return an empty success object
    try {
      final data = jsonDecode(response.body);
      return data;
    } catch (jsonError) {
      print('Success response is not valid JSON, returning generic success object: $jsonError');
      return {'success': true, 'message': 'Update successful'};
    }
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Remove User
Future<Map<String, dynamic>> removeUser(int userid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.delete(
      Uri.parse('$API_URL/users/removeUser/$userid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Suspend User
Future<Map<String, dynamic>> suspendUser(int userid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.put(
      Uri.parse('$API_URL/users/suspendUser/$userid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to suspend user');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Activate User
Future<Map<String, dynamic>> activateUser(int userid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.put(
      Uri.parse('$API_URL/users/activateUser/$userid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to activate user');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Nodemailer For Contact Us
Future<Map<String, dynamic>> sendContactEmail(Map<String, dynamic> emailData) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/contact_us'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailData),
    );

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Booking Request Notification
Future<Map<String, dynamic>> requestBooking(int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/requestBooking/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send booking request notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Booking Accepted Notification
Future<Map<String, dynamic>> acceptBooking(int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/accept_booking/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send booking accepted notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Suggest New Room
Future<Map<String, dynamic>> suggestNewRoom(int propertyid, int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/suggestNewRoom/$propertyid/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send new room suggested notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Property Listing Request Notification
Future<Map<String, dynamic>> propertyListingRequest(int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/propertyListingRequest/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send property listing request notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Property Listing Request Accepted Notification
Future<Map<String, dynamic>> propertyListingAccept(int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/propertyListingAccept/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send property listing request accepted notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Property Listing Request Rejected Notification
Future<Map<String, dynamic>> propertyListingReject(int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/propertyListingReject/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send property listing request rejected notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Send Suggest Notification 
Future<Map<String, dynamic>> sendSuggestNotification(int reservationid, List<int> selectedOperators) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/sendSuggestNotification/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userids': selectedOperators,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send suggest notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Send Picked Up Notification To Original Reservation Owner
Future<Map<String, dynamic>> sendPickedUpNotification(int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/sendPickedUpNotification/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send picked up notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Send Suggested Room Rejected Message To Operators
Future<Map<String, dynamic>> rejectSuggestedRoom(int propertyid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/reject_suggested_room/$propertyid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send suggested room rejected notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Store Reservation Data
Future<Map<String, dynamic>> createReservation(Map<String, dynamic> reservationData) async {
  final userid = await Session.getUserId();
  final creatorid = await Session.getUserId();
  final username = await Session.getUsername();
  final creatorUsername = username ?? 'user_${creatorid ?? 0}';
  
  try {
    if (userid == null) {
      throw Exception('User not logged in. Please log in to create a reservation.');
    }

    print('API: Creating reservation for userid: $userid, username: $creatorUsername');
    print('API: Reservation data: $reservationData');

    final reservationWithuserid = {...reservationData, 'userid': userid};
    
    final response = await http.post(
      Uri.parse('$API_URL/reservation/$userid?creatorid=$creatorid&creatorUsername=${Uri.encodeComponent(creatorUsername)}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(reservationWithuserid),
    );

    print('API: Reservation response status: ${response.statusCode}');
    print('API: Reservation response body: ${response.body}');

    // Accept both 200 (OK) and 201 (Created) as success status codes
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errorData = jsonDecode(response.body);
        // Try to get detailed error message, fallback to generic message
        final errorMessage = errorData['details'] ?? 
                            errorData['error'] ?? 
                            errorData['message'] ?? 
                            'Failed to create reservation';
        print('API: Server error: ${response.statusCode} ${response.reasonPhrase}');
        print('API: Error data: $errorData');
        throw Exception(errorMessage);
      } catch (e) {
        if (e is Exception) {
          rethrow;
        }
        // If JSON parsing fails, use the raw response
        print('API: Failed to parse error response, using raw body');
        throw Exception('Failed to create reservation: ${response.statusCode} ${response.reasonPhrase}');
      }
    }

    final result = jsonDecode(response.body);
    if (result == null || result['reservationid'] == null) {
      throw Exception('No valid reservation ID received from server');
    }

    print('API: Reservation created successfully with ID: ${result['reservationid']}');
    return result;
  } catch (error) {
    print('API error creating reservation: $error');
    rethrow;
  }
}

// Fetch all Reservations
Future<List<dynamic>> fetchReservation() async {
  final username = await Session.getUsername();
  
  try {
    if (username == null || username.isEmpty) {
      print('API: Username not found in session, returning empty reservations');
      return [];
    }

    print('API: Fetching reservations for username: $username');
    final response = await http.get(
      Uri.parse('$API_URL/reservationTable?username=${Uri.encodeComponent(username)}'),
    );

    print('API: Reservations response status: ${response.statusCode}');

    // 404 means no reservations found - that's okay
    if (response.statusCode == 404) {
      print('API: No reservations found (404), returning empty list');
      return [];
    }

    if (response.statusCode != 200) {
      print('API: Unexpected status ${response.statusCode}, returning empty list');
      return [];
    }

    final data = jsonDecode(response.body);
    
    // Try different possible keys
    if (data['reservations'] != null && data['reservations'] is List) {
      print('API: Found ${(data['reservations'] as List).length} reservations');
      return data['reservations'];
    } else if (data is List) {
      print('API: Response is direct list with ${data.length} reservations');
      return data;
    }
    
    return [];
  } catch (error) {
    print('API error fetching reservations: $error');
    return [];
  }
}

// Update reservation status
Future<Map<String, dynamic>> updateReservationStatus(int reservationid, String status) async {
  final userid = await Session.getUserId();
  
  try {
    final response = await http.patch(
      Uri.parse('$API_URL/updateReservationStatus/$reservationid?userid=$userid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reservationStatus': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update reservation status');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Cart
Future<List<dynamic>> fetchCart() async {
  final userid = await Session.getUserId();
  
  try {
    if (userid == null) {
      print('API: User ID not found in session, returning empty cart');
      return [];
    }

    print('API: Fetching cart for userid: $userid');
    final response = await http.get(
      Uri.parse('$API_URL/cart?userid=$userid'),
    );

    print('API: Cart response status: ${response.statusCode}');

    // 404 means no cart items found - that's okay
    if (response.statusCode == 404) {
      print('API: No cart items found (404), returning empty list');
      return [];
    }

    if (response.statusCode != 200) {
      print('API: Unexpected status ${response.statusCode}, returning empty list');
      return [];
    }

    final data = jsonDecode(response.body);
    
    // Try different possible keys
    if (data['reservations'] != null && data['reservations'] is List) {
      print('API: Found ${(data['reservations'] as List).length} cart items');
      return data['reservations'];
    } else if (data is List) {
      print('API: Response is direct list with ${data.length} cart items');
      return data;
    }
    
    return [];
  } catch (error) {
    print('API error fetching cart: $error');
    return [];
  }
}

// Get property owner's PayPal ID
Future<Map<String, dynamic>> getPropertyOwnerPayPalId(int propertyId) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/property/owner-paypal/$propertyId'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch property owner PayPal ID');
    }
    
    final data = jsonDecode(response.body);

    return {
      'payPalId': data['payPalId'],
      'ownerName': data['ownerName']
    };
  } catch (error) {
    print('API error fetching PayPal ID: $error');
    rethrow;
  }
}

// Remove Reservation
Future<Map<String, dynamic>> removeReservation(int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.delete(
      Uri.parse('$API_URL/removeReservation/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete reservation');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Book & Pay Log
Future<Map<String, dynamic>> fetchBookLog(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/booklog?userid=$userid'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch book logs');
    }

    final data = jsonDecode(response.body);

    return data; 
  } catch (error) {
    print('API error fetching book logs: $error');
    rethrow;
  }
}

// Fetch Finance 
Future<Map<String, dynamic>> fetchFinance(int userid) async {
  try {
    print('API: Fetching finance for userid: $userid');
    final response = await http.get(
      Uri.parse('$API_URL/users/finance?userid=$userid'),
    );
    
    print('API: Finance response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('API: Finance returned status ${response.statusCode}, returning empty');
      return {};
    }
    
    final data = jsonDecode(response.body);
    print('API: Finance data keys: ${data.keys.toList()}');
      return data; 
  } catch (error) {
    print('API error fetching finance: $error');
    return {};
  }
}

// Fetch Occupancy Rate
Future<Map<String, dynamic>> fetchOccupancyRate(int userid) async {
  try {
    print('API: Fetching occupancy rate for userid: $userid');
    final response = await http.get(
      Uri.parse('$API_URL/users/occupancy_rate?userid=$userid'),
    );
    
    print('API: Occupancy rate response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('API: Occupancy rate returned status ${response.statusCode}, returning empty');
      return {};
    }
    
    final data = jsonDecode(response.body);
    print('API: Occupancy rate data keys: ${data.keys.toList()}');
      return data; 
  } catch (error) {
    print('API error fetching occupancy rate: $error');
    return {};
  }
}

// Fetch Reservation per Available Room
Future<Map<String, dynamic>> fetchRevPAR(int userid) async {
  try {
    print('API: Fetching RevPAR for userid: $userid');
    final response = await http.get(
      Uri.parse('$API_URL/users/RevPAR?userid=$userid'),
    );
    
    print('API: RevPAR response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('API: RevPAR returned status ${response.statusCode}, returning empty');
      return {};
    }
    
    final data = jsonDecode(response.body);
    print('API: RevPAR data keys: ${data.keys.toList()}');
      return data; 
  } catch (error) {
    print('API error fetching RevPAR: $error');
    return {};
  }
}

// Fetch Cancellation Rate
Future<Map<String, dynamic>> fetchCancellationRate(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/cancellation_rate?userid=$userid'),
    );
    final data = jsonDecode(response.body);
      return data; 
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Customer Retention Rate
Future<Map<String, dynamic>> fetchCustomerRetentionRate(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/customer_retention_rate?userid=$userid'),
    );
    final data = jsonDecode(response.body);
      return data; 
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Guest Satisfaction Score
Future<Map<String, dynamic>> fetchGuestSatisfactionScore(int userid) async {
  try {
    print('API: Fetching guest satisfaction score for userid: $userid');
    final response = await http.get(
      Uri.parse('$API_URL/users/guest_satisfaction_score?userid=$userid'),
    );
    
    print('API: Guest satisfaction response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('API: Guest satisfaction returned status ${response.statusCode}, returning empty');
      return {};
    }
    
    final data = jsonDecode(response.body);
    print('API: Guest satisfaction data keys: ${data.keys.toList()}');
      return data; 
  } catch (error) {
    print('API error fetching guest satisfaction: $error');
    return {};
  }
}

// Fetch Average Length of Stay
Future<Map<String, dynamic>> fetchALOS(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/alos?userid=$userid'),
    );
    final data = jsonDecode(response.body);
      return data; 
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Get Properties Of Administrator For "Suggest"
Future<Map<String, dynamic>> getOperatorProperties(int userid, int reservationid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/operatorProperties/$userid/$reservationid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to get properties');
    }

    final data = jsonDecode(response.body);
    return data;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch normal user data
Future<Map<String, dynamic>> fetchUserData(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/users/$userid'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch user data');
    }
    
    return jsonDecode(response.body);
  } catch (error) {
    print('Error fetching user data: $error');
    rethrow;
  }
}

// Fetch google user data
Future<Map<String, dynamic>?> fetchGoogleUserData(String accessToken) async {
  try {
    final response = await http.get(
      Uri.parse('https://www.googleapis.com/oauth2/v1/userinfo?access_token=$accessToken'),
          headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
          },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch Google user data');
      }

    final profile = jsonDecode(response.body);
      return profile;
  } catch (error) {
    print("Error fetching Google user data: $error");
      return null;
  }
}

// Update user profile
Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
    
    try {
        // Validate user ID
    if (userData['userid'] == null) {
      throw Exception('User ID is missing');
        }
      
    final response = await http.put(
      Uri.parse('$API_URL/users/updateProfile/${userData['userid']}?creatorid=$creatorid&creatorUsername=$creatorUsername'),
            headers: {
                'Content-Type': 'application/json',
            },
      body: jsonEncode(userData),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update user profile');
    }

    return jsonDecode(response.body);
    } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Upload Avatar
Future<Map<String, dynamic>> uploadAvatar(int userid, String base64String) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;

  try {
    if (userid == 0) {
      throw Exception('User ID is missing');
    }

    final response = await http.post(
      Uri.parse('$API_URL/users/uploadAvatar/$userid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
        headers: {
          'Content-Type': 'application/json',
        },
      body: jsonEncode({'uimage': base64String}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to upload avatar');
      }
  
      return data; 
    } catch (error) {
    print('API error: $error');
    rethrow;
    }
}

// Forgot Password
Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
    final response = await http.post(
      Uri.parse('$API_URL/forgot-password'),
            headers: {
                'Content-Type': 'application/json',
            },
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Reset password failed');
        }

        return data; 
    } catch (error) {
    print('Reset password request error: $error');
    rethrow;
  }
}

// Google Login
Future<Map<String, dynamic>> googleLogin(String token) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      print("Server error response: $errorData");
      throw Exception(errorData['message'] ?? "Google Login Failed");
    }

    final data = jsonDecode(response.body);
        return data;
    } catch (error) {
    print("Error in Google Login: $error");
    rethrow;
    }
}

// Google Map
Future<Map<String, double>> getCoordinates(String location) async {
  final response = await http.get(
    Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(location)}&key=AIzaSyCe27HezKpItahXjMFcWXf3LwFcjI7pZFk'),
  );
  final data = jsonDecode(response.body);
  if (data['results'] != null && (data['results'] as List).isNotEmpty) {
    final location = data['results'][0]['geometry']['location'];
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    return {'lat': lat, 'lng': lng};
  }
  throw Exception('Location not found');
}

// Assign Role
Future<Map<String, dynamic>> assignRole(int userid, String role) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;

  final res = await http.post(
    Uri.parse('$API_URL/users/assignRole/$userid/$role?creatorid=$creatorid&creatorUsername=$creatorUsername'),
    headers: {'Content-Type': 'application/json'},
  );

  final text = res.body;
  Map<String, dynamic> data;

  try {
    data = jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Server returned unexpected response:\n$text');
  }

  if (res.statusCode != 200) {
    throw Exception(data['message'] ?? jsonEncode(data));
  }

  return data;
}

// Fetch Audit Trails
Future<List<dynamic>> auditTrails(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/auditTrails?userid=$userid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch audit trails');
    }

    final data = jsonDecode(response.body);
    return data['auditTrails'];
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Submit a review for a property
Future<Map<String, dynamic>> submitReview(Map<String, dynamic> reviewData) async {
  final userid = await Session.getUserId();
  final creatorUsername = 'user_${userid ?? 0}'; // TODO: Get actual username from session
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/reviews?creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(reviewData),
    );

    print('Response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      print('Server error response: $errorData');
      throw Exception(errorData['message'] ?? 'Failed to submit review');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch reviews for a specific property
Future<Map<String, dynamic>> fetchReviews(int propertyid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/reviews/$propertyid'),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch property reviews');
    }
    
    return jsonDecode(response.body);
  } catch (error) {
    print('Error fetching property reviews: $error');
    rethrow;
  }
}

Future<Map<String, dynamic>> fetchClusters() async {
  try {
    print('API: Fetching clusters... (timestamp: ${DateTime.now().millisecondsSinceEpoch})');
    final response = await http.get(
      Uri.parse('$API_URL/clusters?_t=${DateTime.now().millisecondsSinceEpoch}'),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
    
    print('API: Clusters response status: ${response.statusCode}');
    
    if (response.statusCode != 200) {
      print('API: Clusters returned status ${response.statusCode}, returning empty');
      return {'clusters': []};
    }
    
    final data = jsonDecode(response.body);
    print('API: Clusters data keys: ${data is Map ? (data as Map).keys.toList() : "direct list"}');
    return data is Map ? data as Map<String, dynamic> : {'clusters': data};
  } catch (error) {
    print('Error fetching clusters: $error');
    return {'clusters': []};
  }
}

// Fetch unique cluster names from the database
Future<Map<String, dynamic>> fetchClusterNames() async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/clusters/names'),
    );
    return jsonDecode(response.body);
  } catch (error) {
    print('Error fetching cluster names: $error');
    rethrow;
  }
}

// Fetch Suggested Reservations
Future<Map<String, dynamic>> suggestedReservations(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/suggestedReservations/$userid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch suggested reservations');
    }

    final data = jsonDecode(response.body);
    return data;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Fetch Published Reservations
Future<Map<String, dynamic>> publishedReservations(int userid) async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/publishedReservations/$userid'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to fetch published reservations');
    }

    final data = jsonDecode(response.body);
    return data;
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Add a new cluster
Future<Map<String, dynamic>> addCluster(Map<String, dynamic> clusterData) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/clusters'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(clusterData),
    );

    return jsonDecode(response.body);
  } catch (error) {
    print('Error adding cluster: $error');
    rethrow;
  }
}

// Update an existing cluster
Future<Map<String, dynamic>> updateCluster(int clusterID, Map<String, dynamic> clusterData) async {
  try {
    final response = await http.put(
      Uri.parse('$API_URL/clusters/$clusterID'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(clusterData),
    );

    return jsonDecode(response.body);
  } catch (error) {
    print('Error updating cluster: $error');
    rethrow;
  }
}

// Delete a cluster
Future<Map<String, dynamic>> deleteCluster(int clusterID) async {
  try {
    final response = await http.delete(
      Uri.parse('$API_URL/clusters/$clusterID'),
    );

    return jsonDecode(response.body);
  } catch (error) {
    print('Error deleting cluster: $error');
    rethrow;
  }
}

// Fetch Categories
Future<Map<String, dynamic>> fetchCategories() async {
  try {
    final response = await http.get(
      Uri.parse('$API_URL/categories'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch categories');
    }

    final data = jsonDecode(response.body);
    return data; 
  } catch (error) {
    print('Error fetching categories: $error');
    rethrow;
  }
}

// Payment Successful Notification
Future<Map<String, dynamic>> paymentSuccess(int reservationid) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;
  
  try {
    final response = await http.post(
      Uri.parse('$API_URL/payment_success/$reservationid?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to send payment successful notification');
    }

    return jsonDecode(response.body);
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}

// Add for checking date overlapping
Future<bool> checkDateOverlap(int propertyId, String checkIn) async {
  final creatorid = await Session.getUserId();
  final username = 'user_${creatorid ?? 0}'; // TODO: Get actual username from session
  final creatorUsername = username;

  try {
    final response = await http.post(
      Uri.parse('$API_URL/check-date-overlap/$propertyId?creatorid=$creatorid&creatorUsername=$creatorUsername'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'checkIn': checkIn}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to check date overlap');
    }

    final data = jsonDecode(response.body);
    return data['overlap'];
  } catch (error) {
    print('API error: $error');
    rethrow;
  }
}
