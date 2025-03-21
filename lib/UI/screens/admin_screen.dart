import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Auth/signUp/signup.dart';
import '../widgets/category_tile.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupScreen()),
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          title: const Text(
            "Admin Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 28),
              onPressed: () => logout(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Category",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                children: const [
                  CategoryTile(
                      title: "Medical",
                      color: Colors.redAccent,
                      icon: Icons.health_and_safety),
                  CategoryTile(
                      title: "Violence",
                      color: Colors.blueAccent,
                      icon: Icons.shield_outlined),
                  CategoryTile(
                      title: "Rescue",
                      color: Colors.teal,
                      icon: Icons.support_agent),
                  CategoryTile(
                      title: "Fire",
                      color: Colors.orange,
                      icon: Icons.local_fire_department),
                  CategoryTile(
                      title: "Natural Disaster",
                      color: Colors.purple,
                      icon: Icons.tsunami),
                  CategoryTile(
                      title: "Accident",
                      color: Colors.deepOrange,
                      icon: Icons.directions_car),
                  CategoryTile(
                      title: "Other",
                      color: Colors.brown,
                      icon: Icons.report_gmailerrorred),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
