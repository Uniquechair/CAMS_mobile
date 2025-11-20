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

  // Colors
  final Color primaryBlue = const Color(0xFF4188FF);
  final Color titleBrown = const Color(0xFF4A3426);
  final Color descBrown = const Color(0xFF6E5B4B);

  // animation states
  double _fadeOpacity = 1.0;
  Offset _slideOffset = Offset.zero;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Hello Sarawak!',
      'description': 'Explore stays across the land of the hornbills.',
      'image': 'assets/ob1.png',
    },
    {
      'title': 'Stay Connected',
      'description': 'All your stays in one app.',
      'image': 'assets/ob2.png',
    },
    {
      'title': 'Ready to Begin?',
      'description': 'Start your journey with us.',
      'image': 'assets/ob3.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Run initial fade/slide animation
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFadeAnimation());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _runFadeAnimation() async {
    // Start from slightly down + transparent
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // global background
      backgroundColor: const Color(0xFFFEF8E4),
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

                  return Container(
                    width: double.infinity,
                    color: const Color(0xFFFEF8E4),
                    child: AnimatedSlide(
                      offset: _slideOffset,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: _fadeOpacity,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // IMAGE CENTER
                            Expanded(
                              child: Center(
                                child: Image.asset(
                                  page['image'],
                                  fit: BoxFit.contain,
                                  width: MediaQuery.of(context).size.width * 0.83,
                                ),
                              ),
                            ),

                            // BOTTOM-LEFT TEXT
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    page['title'],
                                    style: GoogleFonts.seymourOne(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w400, // Seymour One has single weight
                                      height: 1.1,
                                      color: titleBrown,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    page['description'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: descBrown,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ----------------- DOT INDICATORS -----------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  height: 8,
                  width: active ? 26 : 8,
                  decoration: BoxDecoration(
                    color: active ? titleBrown : Colors.brown.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),

            // ----------------- GLASSY GRADIENT BUTTON -----------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.90),
                          const Color(0xFF74A9FF).withOpacity(0.95),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
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
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
