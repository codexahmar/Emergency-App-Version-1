import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Auth/signUp/signup.dart';
import 'location_screen.dart';

class RescueScreen extends StatefulWidget {
  const RescueScreen({super.key});

  @override
  State<RescueScreen> createState() => _RescueScreenState();
}

class _RescueScreenState extends State<RescueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to format the timestamp
  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  // Function to open location in app
  void openLocation(GeoPoint location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationScreen(
          initialLatitude: location.latitude,
          initialLongitude: location.longitude,
        ),
      ),
    );
  }

  // Function to fetch user name from Firestore
  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      return 'Unknown User';
    }
  }

  // Function to mark a report as completed
  void markAsCompleted(String reportId) async {
    await FirebaseFirestore.instance
        .collection("incidentReports")
        .doc(reportId)
        .update({"status": "completed"});
  }

  // Function to logout
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

  // Widget to build the report list
  Widget buildReportList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("incidentReports")
          .where("emergencyType", whereIn: [
            "Rescue",
            "Fire",
            "Medical",
            "Natural Disaster",
            "Accident"
          ])
          .where("status", isEqualTo: status)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No rescue reports found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: snapshot.data!.docs.map((doc) {
            String reportId = doc.id;
            GeoPoint location = doc["location"];
            Timestamp timestamp = doc["timestamp"];
            String userId = doc["userId"];
            String emergencyType = doc["emergencyType"];

            // Safely get optional fields
            final Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;
            final String? incidentPic = data['incidentPic'] as String?;
            final String? description = data['description'] as String?;

            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User and Date Row
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 25,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: getUserName(userId),
                                builder: (context, snapshot) {
                                  return Text(
                                    snapshot.data ?? "Unknown User",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                              Text(
                                "Date: ${formatTimestamp(timestamp)}",
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 15, thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            "Emergency: $emergencyType",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                    // Incident Image (if available)
                    if (incidentPic != null && incidentPic.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            incidentPic,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                      ),

                    // Description (if available)
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                    // Location Row
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Lat: ${location.latitude}, Lng: ${location.longitude}",
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => openLocation(location),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("View on Map"),
                        ),
                      ],
                    ),

                    // Mark as Completed button
                    if (status == "active")
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => markAsCompleted(reportId),
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          label: const Text("Mark as Completed",
                              style: TextStyle(color: Colors.green)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
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
            "Rescue Reports",
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
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => logout(context),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Active Reports"),
              Tab(text: "Completed Reports"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildReportList("active"),
          buildReportList("completed"),
        ],
      ),
    );
  }
}
