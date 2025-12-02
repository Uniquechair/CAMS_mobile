import 'package:flutter/material.dart';
import 'dart:convert';
import '../api.dart' as api;
import '../widgets/hs_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  String _group = 'customer'; // Fixed to customer role only

  bool _loading = false;
  String? _msg;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _msg = null; });

    try {
      print('DEBUG: Signup attempt started');
      print('DEBUG: Username: ${_username.text.trim()}');
      print('DEBUG: Selected user group: $_group');
      
      // Call the new API
      final response = await api.signupUser({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'uphoneno': _phone.text.trim(),
        'userGroup': _group,
      });
      
      print('DEBUG: Signup API response status: ${response.statusCode}');
      print('DEBUG: Signup API response body: ${response.body}');
      
      // Parse response
      final data = jsonDecode(response.body);
      
      setState(() => _msg = data['message'] ?? 'Registered successfully');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_msg!)));
      // Go to login after success
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      setState(() => _msg = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _first.dispose(); _last.dispose(); _username.dispose();
    _email.dispose(); _password.dispose(); _phone.dispose();
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
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
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
                          Text('Create your account',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(child: HSTextField(controller: _first, label: 'First name', keyboardType: TextInputType.name)),
                              const SizedBox(width: 12),
                              Expanded(child: HSTextField(controller: _last, label: 'Last name', keyboardType: TextInputType.name)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          HSTextField(controller: _username, label: 'Username'),
                          const SizedBox(height: 12),
                          HSTextField(
                            controller: _email, label: 'Email', keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 12),
                          HSTextField(
                            controller: _phone, label: 'Phone number', keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.length < 6) ? 'Enter a valid phone' : null,
                          ),
                          const SizedBox(height: 12),
                          HSTextField(
                            controller: _password, label: 'Password', obscure: true,
                            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_msg != null)
                            Text(_msg!, style: TextStyle(color: _msg!.toLowerCase().contains('success') ? Colors.green : Colors.red)),
                          const SizedBox(height: 8),
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
                                  : const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? '),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                                child: const Text('Sign In',
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
