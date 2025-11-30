import 'package:flutter/material.dart';
import '../api.dart' as api;

/// Color palette (from your style guide)
const kPrimaryBlue = Color(0xFF0077B6);
const kSmallTextBlue = Color(0xFF0096C7);
const kGradientStart = Color(0xFF5B8DEF);
const kGradientEnd = Color(0xFFE7F0FF);
const kBackgroundAll = Color(0xFFE7F0FF);

/// Common scaffold with gradient and a centered card.
/// - Card is vertically centered on phones & tablets.
/// - Supports scrolling on small screens so nothing overflows.
class AuthScaffold extends StatelessWidget {
  final String backLabel;
  final Widget child;
  final VoidCallback? onBack;

  const AuthScaffold({
    super.key,
    required this.child,
    this.onBack,
    this.backLabel = 'Back to Login',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundAll,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kGradientStart, kGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back to login (stays in the corner; card stays centered)
              Positioned(
                left: 12,
                top: 8,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onBack ?? () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(backLabel),
                ),
              ),

              // Centered content with scroll fallback
              LayoutBuilder(
                builder: (_, c) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Card(
                            elevation: 8,
                            shadowColor: Colors.black12,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 22,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------ 1. Enter Email ------------------
class ForgotPasswordRequestPage extends StatefulWidget {
  const ForgotPasswordRequestPage({super.key});

  @override
  State<ForgotPasswordRequestPage> createState() =>
      _ForgotPasswordRequestPageState();
}

class _ForgotPasswordRequestPageState extends State<ForgotPasswordRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sending = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: kGradientEnd,
                  child: Icon(Icons.mail_outline, color: kPrimaryBlue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Customer Password Recovery',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: kPrimaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Enter your customer email to receive a new password.',
              style: const TextStyle(color: kSmallTextBlue),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                label: 'Customer Email Address',
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Email is required';
                final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v);
                if (!ok) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 12),
            _infoPill(
              icon: Icons.lock_outline,
              text: 'Secure password recovery for customers',
            ),
            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),

            _primaryButton(
              context,
              label: _sending ? 'Sending...' : 'Send New Password',
              onPressed: _sending
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      
                      setState(() {
                        _sending = true;
                        _errorMessage = null;
                      });

                      try {
                        final response = await api.forgotPassword(_email.text.trim());
                        
                        if (!mounted) return;

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              response['message'] ?? 'New password sent to your email',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 3),
                          ),
                        );

                        // Navigate to success page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PasswordResetCompletePage(),
                          ),
                        );
                      } catch (error) {
                        if (!mounted) return;
                        setState(() {
                          _errorMessage = error.toString().replaceAll('Exception: ', '');
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _errorMessage ?? 'Failed to send new password',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => _sending = false);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------ 2. Success Page ------------------
class PasswordResetCompletePage extends StatelessWidget {
  const PasswordResetCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              CircleAvatar(
                radius: 18,
                backgroundColor: kGradientEnd,
                child: Icon(Icons.mark_email_read_outlined,
                    color: kPrimaryBlue),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Password Reset Complete',
                  style: TextStyle(
                    color: kPrimaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const CircleAvatar(
            backgroundColor: Color(0xFFDFF3E3),
            radius: 40,
            child: Icon(Icons.check_circle, color: Colors.green, size: 64),
          ),
          const SizedBox(height: 16),
          const Text(
            'A new password has been sent to your email.\nPlease check your inbox and use the new password to log in.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kSmallTextBlue),
          ),
          const SizedBox(height: 18),
          _primaryButton(
            context,
            label: 'Back to Login',
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}

/// ---------- small UI helpers ----------
InputDecoration _inputDecoration({String? label, String? hint, IconData? icon}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryBlue, width: 1.4),
    ),
  );
}

Widget _primaryButton(BuildContext context,
    {required String label, VoidCallback? onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ),
  );
}

Widget _infoPill({required IconData icon, required String text}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: kGradientEnd,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE0E7FF)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: kPrimaryBlue),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(color: kPrimaryBlue))),
      ],
    ),
  );
}
