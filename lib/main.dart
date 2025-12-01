import 'package:flutter/material.dart';
import 'owner/owner_property_listing.dart';  

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
      home: const OwnerPropertyListingPage(),  
    );
  }
}
