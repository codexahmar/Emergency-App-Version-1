import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../provider/location_provider.dart';
import '../widgets/emergency_container.dart';
import '../widgets/sos_btn.dart';
import 'contacts_screen.dart';
import '../../provider/theme_provider.dart';

class QuickSosAlert extends StatefulWidget {
  const QuickSosAlert({super.key});

  @override
  State<QuickSosAlert> createState() => QuickSosAlertState();
}

class QuickSosAlertState extends State<QuickSosAlert> {
  String? selectedEmergency;
  Timer? holdTimer;

  void startHoldTimer(BuildContext context) {
    holdTimer = Timer(const Duration(seconds: 3), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ContactsScreen()),
      );
    });
  }

  void cancelHoldTimer() {
    holdTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor =
        themeProvider.isDarkMode ? Colors.black : Colors.white;
    final appBarColor =
        themeProvider.isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor =
        themeProvider.isDarkMode ? Colors.white70 : Colors.grey;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                "assets/icons/logo.png",
                height: 40,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.location_on,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Current location",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Consumer<LocationProvider>(
                  builder: (context, locationProvider, child) {
                    return Text(
                      locationProvider.currentLocation,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onLongPress: () => startHoldTimer(context),
                onLongPressUp: cancelHoldTimer,
                child: SOSButton(
                  onPressed: () {},
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            Text(
              "Select Your Emergency Type",
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            SizedBox(height: screenHeight * 0.04),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                EmergencyContainer(
                  icon: "assets/icons/medical.png",
                  color: Color(0xFFDBE790),
                  label: "Medical",
                  isSelected: selectedEmergency == "Medical",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Medical";
                    });
                  },
                ),
                EmergencyContainer(
                  icon: "assets/icons/fire.png",
                  color: Color(0xFFF5A6A6),
                  label: "Fire",
                  isSelected: selectedEmergency == "Fire",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Fire";
                    });
                  },
                ),
                EmergencyContainer(
                  icon: "assets/icons/natural_disaster.png",
                  color: Color(0xFFA6F5D4),
                  label: "Natural Disaster",
                  isSelected: selectedEmergency == "Natural Disaster",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Natural Disaster";
                    });
                  },
                ),
                EmergencyContainer(
                  icon: "assets/icons/accident.png",
                  color: Color(0xFFD4CEFA),
                  label: "Accident",
                  isSelected: selectedEmergency == "Accident",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Accident";
                    });
                  },
                ),
                EmergencyContainer(
                  icon: "assets/icons/violence.png",
                  color: Color(0xFFF5A6DF),
                  label: "Violence",
                  isSelected: selectedEmergency == "Violence",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Violence";
                    });
                  },
                ),
                EmergencyContainer(
                  icon: "assets/icons/rescue.png",
                  color: Color(0xFFF5E8A6),
                  label: "Rescue",
                  isSelected: selectedEmergency == "Rescue",
                  onTap: () {
                    setState(() {
                      selectedEmergency = "Rescue";
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
