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
  bool _obscure = true;

  // --- TEMP PLACEHOLDERS FOR SOCIAL LOGIN ---
  void _googleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Sign-In tapped")),
    );
  }

  void _appleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Apple Sign-In tapped")),
    );
  }

  // --- SUBMIT LOGIN ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      final response = await api.loginUser({
        'username': _username.text.trim(),
        'password': _password.text,
      });

      final data = jsonDecode(response.body);

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? "Login failed");
      }

      final userid = (data['userid'] as num).toInt();
      final usergroup = data['usergroup'].toString().trim().toLowerCase();
      final uactivation = data['uactivation'].toString().trim().toLowerCase();
      final username = data['username'] ?? _username.text.trim();

      await Session.saveLogin(
        userid: userid,
        usergroup: usergroup,
        uactivation: uactivation,
        username: username,
      );

      if (!mounted) return;

      appNavigatorKey.currentState!.popUntil((r) => r.isFirst);
      await appNavigatorKey.currentState!
          .pushReplacementNamed('/after-login');
    } catch (err) {
      setState(() {
        _msg = err.toString();
        _loading = false;
      });
    }
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
                            onPressed: _googleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                            ),
                            child: Row(
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

                        // --- APPLE SIGN IN BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _appleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.apple,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "Sign in with Apple",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),

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
