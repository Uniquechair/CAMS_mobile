import 'package:flutter/material.dart';
import 'admin_usermanagement.dart';

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
        // (Intentionally no global cardTheme; we style Cards locally in the page)
        useMaterial3: true,
      ),
      home: const AdminUserManagementPage(viewerRole: AppRole.admin),
    );
  }
}
