import 'package:flutter/material.dart';
import 'owner_reservation.dart';  // <-- add this import

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
      home: const OwnerReservationPage(),   // <-- open this page directly
    );
  }
}
