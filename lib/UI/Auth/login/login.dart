import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_app/UI/Auth/signUp/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../provider/theme_provider.dart';
import '../../../services/firebase_api.dart';
import '../../Colors/colors.dart';
import '../../screens/home_screen.dart';
import '../../widgets/custom_textfield.dart';
import '../../screens/admin_screen.dart';
import '../../screens/rescue_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      FirebaseApi firebaseApi = FirebaseApi();

      String? fcmToken = await firebaseApi.firebaseMessaging.getToken();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      String userId = userCredential.user!.uid;

      // Create or update user document in Firestore
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot userData = await userRef.get();

      if (userData.exists) {
        String? userRole = userData.get('role') as String?;

        // Save user role to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', userRole ?? 'user');

        // Update FCM token for existing user
        await userRef.update({
          'fcmToken': fcmToken,
        });

        if (userRole == 'admin') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => AdminScreen()));
        } else if (userRole == 'rescue') {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => RescueScreen()));
        } else if (userRole == "user") {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
        }
      } else {
        await userRef.set({
          'email': emailController.text,
          'fcmToken': fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email not found!')),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect password!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: ${e.message}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Welcome Back",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 50),
            const Text(
              "Email",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: emailController,
              hintText: "Enter your email",
              prefixIcon: Icons.email,
            ),
            const SizedBox(height: 30),
            const Text(
              "Password",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: passwordController,
              hintText: "Enter your password",
              prefixIcon: Icons.lock,
              isPassword: true,
            ),
            SizedBox(
              height: 50,
            ),
            Center(
              child: InkWell(
                onTap: isLoading ? null : login,
                child: Container(
                  width: 288,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: themeProvider.isDarkMode
                        ? Colors.grey[800]
                        : primaryColor,
                  ),
                  child: Center(
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SignupScreen()));
                },
                child: RichText(
                  text: TextSpan(
                    text: "Register your account  ",
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: "Sign Up",
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
