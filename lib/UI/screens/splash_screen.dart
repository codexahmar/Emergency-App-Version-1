import 'package:emergency_app/UI/Colors/colors.dart';

import 'package:emergency_app/UI/Auth/signUp/signup.dart';
import 'package:emergency_app/UI/screens/admin_screen.dart';
import 'package:emergency_app/UI/screens/rescue_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user role from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        String? userRole = prefs.getString('userRole');

        if (userRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        } else if (userRole == 'rescue') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RescueScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Image.asset("assets/images/ambulance.png"),
          ),
          const SizedBox(height: 20),
          const Text(
            "Welcome to Emergency App",
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ],
      ),
    );
  }
}
