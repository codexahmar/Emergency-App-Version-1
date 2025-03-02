import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';

import '../widgets/custom_drawer.dart';
import 'contacts_screen.dart';
import 'first_aid_screen.dart';
import 'incident_reporting.dart';
import 'location_screen.dart';
import 'quick_sos.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Widget fetchUserName() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error loading user data");
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("User not found");
        }

        final userName = snapshot.data!['name'] ?? 'Unknown User';

        return MyDrawer(
          userName: userName,
          userProfilePic: "assets/images/dummy.jpg",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final double padding = screenWidth < 400 ? 8 : 16;
    final double gridSpacing = screenWidth < 400 ? 8 : 12;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        centerTitle: true,
        title: const Text(
          "One tap emergency alert",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        iconTheme: IconThemeData(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      drawer: fetchUserName(),
      body: Column(
        children: [
          Image.asset(
            "assets/images/banner.png",
            width: screenWidth,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth < 600 ? 2 : 3,
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
                childAspectRatio: 1.75,
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
                final containerData = [
                  {
                    "icon": "assets/icons/sos.png",
                    "title": "Quick SOS Alert",
                    "screen": QuickSosAlert(),
                  },
                  {
                    "icon": "assets/icons/contacts.png",
                    "title": "Easily Access Contacts",
                    "screen": ContactsScreen(),
                  },
                  {
                    "icon": "assets/icons/location.png",
                    "title": "Share Real-time Location",
                    "screen": LocationScreen(),
                  },
                  {
                    "icon": "assets/icons/first_aid.png",
                    "title": "First Aid Guidelines",
                    "screen": FirstAidScreen(),
                  },
                  {
                    "icon": "assets/icons/incident_reporting.png",
                    "title": "Incident Reporting with photo",
                    "screen": IncidentReportingScreen(),
                  },
                ];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              containerData[index]["screen"] as Widget),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8DECF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            containerData[index]["icon"] as String,
                            height: 30,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            containerData[index]["title"] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
