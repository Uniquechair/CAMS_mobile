import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../api.dart' as api;
import '../services/session.dart';
import '../widgets/hs_text_field.dart';
import '../app.dart';
import '../admin/admin_dashboard.dart';
import '../moderator/moderator_dashboard.dart';
import '../owner/owner_dashboard.dart';
import '../customer/customer_rooms.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _msg;

  bool _obscure = true;
  bool _googleLoading = false;

  // Google Sign-In
  Future<void> _googleSignIn() async {
    setState(() {
      _googleLoading = true;
      _msg = null;
    });

    try {
      print('DEBUG: Google Sign-In attempt started');

      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        print('DEBUG: Google Sign-In cancelled by user');
        setState(() {
          _googleLoading = false;
        });
        return;
      }

      print('DEBUG: Google Sign-In successful, email: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Get the ID token
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      print('DEBUG: Got Google ID token, sending to backend');

      // Send token to backend
      final response = await api.googleLogin(idToken);
      
      print('DEBUG: Google Login API response: $response');

      // Validate response
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Google login failed');
      }

      final userid = (response['userid'] as num).toInt();
      final usergroup = (response['usergroup'] as String).trim().toLowerCase();
      final uactivation = (response['uactivation'] as String).trim().toLowerCase();
      final username = response['username'] as String? ?? googleUser.email.split('@')[0];
      
      print('DEBUG: Parsed userid: $userid, usergroup: $usergroup, uactivation: $uactivation, username: $username');

      // Save session data
      await Session.saveLogin(
        userid: userid,
        usergroup: usergroup,
        uactivation: uactivation,
        username: username,
      );
      print('DEBUG: Session saved successfully');

      if (!mounted) {
        print('DEBUG: Widget not mounted after session save');
        return;
      }

      // Clear loading state before navigation
      setState(() => _googleLoading = false);

      // Unfocus keyboard
      FocusScope.of(context).unfocus();

      // Navigate to role-based dashboard
      try {
        final nav = appNavigatorKey.currentState!;
        nav.popUntil((r) => r.isFirst);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await nav.pushReplacementNamed('/after-login');
        print('DEBUG: Navigation to /after-login completed');
      } catch (navErr) {
        print('DEBUG: Navigation failed: $navErr');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation error: $navErr')),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Google Sign-In error: $e');
      if (mounted) {
        setState(() {
          _msg = e.toString().replaceAll('Exception: ', '');
          _googleLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _msg ?? 'Google Sign-In failed',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // SUBMIT LOGIN

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      print('DEBUG: Login attempt started for username: ${_username.text.trim()}');
      
      // Call the new API
      final response = await api.loginUser({
        'username': _username.text.trim(),
        'password': _password.text,
      });
      
      print('DEBUG: Login API response status: ${response.statusCode}');
      print('DEBUG: Login API response body: ${response.body}');
      
      // Parse response
      final data = jsonDecode(response.body);
      
      // Validate response data
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Login failed');
      }

      final userid = (data['userid'] as num).toInt();
      final usergroup = (data['usergroup'] as String).trim().toLowerCase();
      final uactivation = (data['uactivation'] as String).trim().toLowerCase();
      final username = data['username'] as String? ?? _username.text.trim();
      
      print('DEBUG: Parsed userid: $userid, usergroup: $usergroup, uactivation: $uactivation, username: $username');

      // Save session data including username
      await Session.saveLogin(
        userid: userid,
        usergroup: usergroup,
        uactivation: uactivation,
        username: username,
      );
      print('DEBUG: Session saved successfully (with username)');
      
      if (!mounted) {
        print('DEBUG: Widget not mounted after session save');
        return;
      }

      // Navigate to role-based dashboard
      String route;
      switch (usergroup) {
        case 'admin':
        case 'administrator':
          route = '/admin';
          break;
        case 'moderator':
          route = '/moderator';
          break;
        case 'owner':
          route = '/owner';
          break;
        case 'customer':
        default:
          route = '/home';
          break;
      }
      
      print('DEBUG: Navigating to route: $route for role: $usergroup');
      
      if (mounted) {
        // Clear loading state before navigation
        setState(() => _loading = false);
        
        // Unfocus keyboard to avoid IME/transition issues
        FocusScope.of(context).unfocus();
        
        // Delegate routing to app.dart central redirect
        try {
          final nav = appNavigatorKey.currentState!;
          nav.popUntil((r) => r.isFirst);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await nav.pushReplacementNamed('/after-login');
          print('DEBUG: Navigation to /after-login completed');
        } catch (navErr) {
          print('DEBUG: Navigation failed: ' + navErr.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigation error: ' + navErr.toString())),
            );
          }
        }
      }
    } catch (e) {
      print('DEBUG: Login error: $e');
      if (mounted) {
        setState(() {
          _msg = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _username.dispose(); 
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B8DEF), // blue
              Color(0xFFE7F0FF), // very light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // TITLE
                        const Text(
                          "Hello Sarawak!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F497B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),

                        const SizedBox(height: 26),

                        // USERNAME FIELD
                        HSTextField(
                          controller: _username,
                          label: 'Username',
                        ),
                        const SizedBox(height: 14),

                        // PASSWORD FIELD
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        if (_msg != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _msg!,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.error),
                            ),
                          ),

                        // SIGN IN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0077B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  )
                                : const Text(
                                    "Sign In",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- DIVIDER ---
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    thickness: 1,
                                    color: Colors.grey.shade300)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "or continue with",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    thickness: 1,
                                    color: Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // --- GOOGLE SIGN IN BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_googleLoading || _loading) ? null : _googleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            child: _googleLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0077B6),
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/google_logo.png',
                                        height: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        "Sign in with Google",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const SizedBox(height: 22),

                        // --- CREATE ACCOUNT ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style:
                                  TextStyle(color: Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/signup'),
                              child: const Text(
                                "Create one",
                                style: TextStyle(
                                  color: Color(0xFF0077B6),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 8),

                        // --- FORGOT PASSWORD ---
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/forget-password'),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Color(0xFF0077B6),
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
          ),
        ),
      ),
    );
  }
}
