import 'package:flutter/material.dart';
import '/settings_page.dart';
import '/login_page.dart';

class ProfilePage extends StatelessWidget {
  final String userName;
  final String userEmail;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🧑 Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsPage()),
                      );
                    },
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ℹ️ Account Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Account Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20, thickness: 1),
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blueAccent),
                    title: const Text("Username"),
                    subtitle: Text(userName),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.email_outlined, color: Colors.blueAccent),
                    title: const Text("Email"),
                    subtitle: Text(userEmail),
                  ),
                  const ListTile(
                    leading: Icon(Icons.verified_user, color: Colors.blueAccent),
                    title: Text("Account Status"),
                    subtitle: Text("Active"),
                  ),
                  const ListTile(
                    leading: Icon(Icons.group, color: Colors.blueAccent),
                    title: Text("User Role"),
                    subtitle: Text("Customer"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🚪 Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
