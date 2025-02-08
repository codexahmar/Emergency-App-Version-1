import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/location_provider.dart';
import '../widgets/emergency_container.dart';
import '../widgets/sos_btn.dart';

class QuickSosAlert extends StatefulWidget {
  const QuickSosAlert({super.key});

  @override
  State<QuickSosAlert> createState() => _QuickSosAlertState();
}

class _QuickSosAlertState extends State<QuickSosAlert> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SOSButton(
                onPressed: () {
                  print("SOS Activated!");
                },
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Select Your Emergency Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 30),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                EmergencyContainer(
                  icon: "assets/icons/medical.png",
                  color: Color(0xFFDBE790),
                  label: "Medical",
                ),
                EmergencyContainer(
                  icon: "assets/icons/fire.png",
                  color: Color(0xFFF5A6A6),
                  label: "Fire",
                ),
                EmergencyContainer(
                  icon: "assets/icons/natural_disaster.png",
                  color: Color(0xFFA6F5D4),
                  label: "Natural Disaster",
                ),
                EmergencyContainer(
                  icon: "assets/icons/accident.png",
                  color: Color(0xFFD4CEFA),
                  label: "Accident",
                ),
                EmergencyContainer(
                  icon: "assets/icons/violence.png",
                  color: Color(0xFFF5A6DF),
                  label: "Violence",
                ),
                EmergencyContainer(
                  icon: "assets/icons/rescue.png",
                  color: Color(0xFFF5E8A6),
                  label: "Rescue",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
