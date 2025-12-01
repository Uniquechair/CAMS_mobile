import 'package:flutter/material.dart';
// import 'onboarding_screen.dart';  // <-- add this import
import 'profile_page.dart';  

void main() {
  runApp(const CamsApp());
}

class CamsApp extends StatelessWidget {
  const CamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CAMS',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const ProfilePage(),   // <-- open this page directly
    );
  }
}
