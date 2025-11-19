import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const String _keyUserId = 'user_id';
  static const String _keyUserGroup = 'user_group';
  static const String _keyUserActivation = 'user_activation';
  static const String _keyUsername = 'username';
  static const String _keySeenOnboarding = 'seen_onboarding';

  // Save login data
  static Future<void> saveLogin({
    required int userid,
    required String usergroup,
    required String uactivation,
    String? username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userid);
    await prefs.setString(_keyUserGroup, usergroup);
    await prefs.setString(_keyUserActivation, uactivation);
    if (username != null) {
      await prefs.setString(_keyUsername, username);
    }
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  // Get username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }

  // Get user group
  static Future<String?> getUserGroup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserGroup);
  }

  // Get user activation status
  static Future<String?> getUserActivation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserActivation);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null;
  }

  // Mark onboarding as seen
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySeenOnboarding, true);
  }

  // Check if onboarding has been seen
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySeenOnboarding) ?? false;
  }

  // Clear all session data
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserGroup);
    await prefs.remove(_keyUserActivation);
    await prefs.remove(_keyUsername);
  }
}
