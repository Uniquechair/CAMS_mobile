import 'package:flutter/material.dart';
import 'dart:convert';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B8DEF), // Dark blue
              Color(0xFFE7F0FF), // Light blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text('Hello Sarawak!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800, color: const Color(0xFF0077B6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Sign in to continue',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                          const SizedBox(height: 18),

                          HSTextField(controller: _username, label: 'Username'),
                          const SizedBox(height: 12),
                          HSTextField(controller: _password, label: 'Password', obscure: true),
                          const SizedBox(height: 16),
                          if (_msg != null) ...[
                            Text(
                              _msg!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0077B6),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0077B6)),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? "),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
                                child: const Text('Create one',
                                    style: TextStyle(color: Color(0xFF0077B6), fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
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
