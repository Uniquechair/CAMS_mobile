import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/session.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // animation states
  double _fadeOpacity = 1.0;
  Offset _slideOffset = Offset.zero;

  final Color descColor = const Color(0xFF6E5B4B);

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Hello, \nSarawak!',
      'description': 'Explore stays across the land of the hornbills.',
      'image': 'assets/ob1.png',
    },
    {
      'title': 'Stay\nConnected',
      'description': 'All your stays in one app.',
      'image': 'assets/ob2.png',
    },
    {
      'title': 'Ready to\nBegin?',
      'description': 'Start your journey with us.',
      'image': 'assets/ob3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFadeAnimation());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _runFadeAnimation() async {
    setState(() {
      _fadeOpacity = 0;
      _slideOffset = const Offset(0, 0.03);
    });

    await Future.delayed(const Duration(milliseconds: 20));
    if (!mounted) return;

    setState(() {
      _fadeOpacity = 1;
      _slideOffset = Offset.zero;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    await Session.markOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/before-login');
    }
  }

  // Gradient title using Seymour One + Figma colours
  Widget _buildGradientTitle(String text) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Color(0xFFFF9F1C), // 0%
            Color(0xFFF88449), // 50%
            Color(0xFFFFBF68), // 100%
          ],
        ).createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.seymourOne(
          fontSize: 29,
          height: 1.1,
          color: Colors.white, // replaced by shader
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ----------------- PAGES -----------------------
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _runFadeAnimation();
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];

                  return AnimatedSlide(
                    offset: _slideOffset,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: _fadeOpacity,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // header size
                          final headerHeight = constraints.maxHeight * 0.55;

                          // tweak overlap + spacing for last page (characters are taller)
                          final bool isLast = index == 2;
                          final double overlapFactor =
                              isLast ? 0.12 : 0.15; // smaller = further up
                          final double spacerFactor =
                              isLast ? 0.10 : 0.08; // more gap below image

                          return Column(
                            children: [
                              const SizedBox(height: 8),

                              // 🔶 TOP: wave + image (with overlap)
                              SizedBox(
                                height: headerHeight,
                                width: double.infinity,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    ClipPath(
                                      clipper: BottomWaveClipper(),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.topRight,
                                            colors: [
                                              Color(0xFFFF9F1C), // 0%
                                              Color(0xFFF88449), // 50%
                                              Color(0xFFFFBF68), // 100%
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Image sitting slightly out of the curve
                                    Positioned(
                                      bottom:
                                          -constraints.maxHeight * overlapFactor,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Image.asset(
                                          page['image'],
                                          width: constraints.maxWidth * 0.55,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // space to account for the image overlap
                              SizedBox(
                                  height:
                                      constraints.maxHeight * spacerFactor),

                              // 🔶 Title, description, dots (middle area)
                              _buildGradientTitle(page['title']),
                              const SizedBox(height: 10),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  page['description'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.4,
                                    color: descColor,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 90),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_pages.length, (i) {
                                  final active = i == _currentPage;
                                  return AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    height: 8,
                                    width: active ? 22 : 8,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? const Color(0xFFDF6A1F)
                                          : const Color(0xFFFFD6A6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  );
                                }),
                              ),

                              const Spacer(),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ----------------- BOTTOM: SKIP + BUTTON -----------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SKIP (grey, left)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Gradient NEXT / GET STARTED button
                  SizedBox(
                    height: 50,
                    width: 130,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFBF68), // 0%
                              Color(0xFFFF9F1C), // 100%
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33FF9F1C),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'GET STARTED'
                                : 'NEXT',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates a smooth “wave” similar to the Figma yellow curve.
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);

    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 60,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
