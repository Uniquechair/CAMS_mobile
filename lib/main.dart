import 'package:flutter/material.dart';
import 'homepage.dart';
// import 'moderator_dashboard.dart';
// import 'admin_dashboard.dart';
// import 'owner_dashboard.dart';

void main() {
  runApp(const CamsApp());
}

class CamsApp extends StatelessWidget {
  const CamsApp({super.key});

  // Brand colors
  static const _brandOrange = Color(0xFFC65A20);
  static const _cream = Color(0xFFFBF2E8);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CAMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandOrange,
          primary: _brandOrange,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: _cream,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        // ✅ Use CardThemeData on newer Flutter
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      // home: const AdminDashboard(),
      // home: const ModeratorDashboard(),
      // home: const OwnerDashboard(),
    );
  }
}
