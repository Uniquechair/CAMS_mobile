import 'package:flutter/material.dart';
import 'shared_admin_moderator/manage_booking.dart';  // 👈 adjust if folder name different

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
      home: const AdminManageBooking(),  // opens Manage Booking directly
    );
  }
}
