import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'admin_managebooking.dart';
=======
//import 'homepage.dart';
// import 'moderator_dashboard.dart';
// import 'admin_dashboard.dart';
// import 'owner_dashboard.dart';
// import 'customer_rooms.dart';
//import 'customer_rooms_not_login.dart';
import 'signup_screen.dart';
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
      home: const AdminManageBooking(),
=======
      //home: const HomePage(),
      // home: const AdminDashboard(),
      // home: const ModeratorDashboard(),
      // home: const OwnerDashboard(),
      // home: const RoomsPage(),
      //home: const CustomerRoomsNotLogin(),
      home: const SignupScreen(),
>>>>>>> Stashed changes
    );
  }
}
