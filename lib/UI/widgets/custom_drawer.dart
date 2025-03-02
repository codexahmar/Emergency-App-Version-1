import 'package:emergency_app/UI/screens/my_profile.dart';
import 'package:emergency_app/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Auth/signUp/signup.dart';
import '../Colors/colors.dart';

class MyDrawer extends StatelessWidget {
  final String userName;
  final String userProfilePic;

  const MyDrawer({
    super.key,
    required this.userName,
    required this.userProfilePic,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    themeProvider.loadThemePreference();
    final backgroundColor =
        themeProvider.isDarkMode ? Colors.black : primaryColor;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.white;

    return Drawer(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage(userProfilePic),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $userName!",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "View and edit your profile",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MyprofileScreen()),
              );
            },
            child: ListTile(
              leading: Image.asset(
                "assets/icons/heart.png",
                height: 25,
              ),
              title: const Text('My Profile'),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      themeProvider.isDarkMode ? primaryColor : Colors.black),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Image.asset(
              "assets/icons/logout.png",
              height: 25,
            ),
            title: const Text('Logout'),
            trailing: Icon(Icons.arrow_forward_ios,
                size: 16,
                color: themeProvider.isDarkMode ? primaryColor : Colors.black),
            onTap: () {
              showCustomDialog(
                context,
                title: 'Logout',
                content: 'Are you sure you want to logout?',
                icon: Icons.logout,
                confirmButtonText: 'Logout',
                confirmAction: () {
                  logout(context);
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.brightness_6,
                color: themeProvider.isDarkMode ? primaryColor : primaryColor),
            title: Text('Toggle Dark Mode',
                style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.black)),
            trailing: Switch(
              activeColor: Colors.white,
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }

  void showCustomDialog(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required String confirmButtonText,
    required VoidCallback confirmAction,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(icon, color: primaryColor),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: confirmAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: Text(
                confirmButtonText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupScreen()),
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }
}
