import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsListScreen extends StatefulWidget {
  final String category;
  const ReportsListScreen({super.key, required this.category});

  @override
  _ReportsListScreenState createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen>
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

  // Function to open location in Google Maps
  void openLocation(GeoPoint location) async {
    String googleMapsAppUrl =
        "geo:${location.latitude},${location.longitude}?q=${location.latitude},${location.longitude}";
    String googleMapsWebUrl =
        "https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}";

    if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
      await launchUrl(Uri.parse(googleMapsAppUrl));
    } else if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
      await launchUrl(Uri.parse(googleMapsWebUrl));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps.")),
      );
    }
  }

  // Function to fetch user name from Firestore based on userId
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

  // Widget to build the report list
  Widget buildReportList(String status) {
    // Create a query based on whether we're looking for "Other" reports or specific emergency types
    Query query = widget.category == "Other"
        ? FirebaseFirestore.instance
            .collection("incidentReports")
            .where("status", isEqualTo: status)
            .orderBy("timestamp", descending: true)
        : FirebaseFirestore.instance
            .collection("incidentReports")
            .where("emergencyType", isEqualTo: widget.category)
            .where("status", isEqualTo: status)
            .orderBy("timestamp", descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Text("No reports found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
        }

        // Filter the documents for "Other" category to only show those without emergencyType
        var docs = snapshot.data!.docs;
        if (widget.category == "Other") {
          docs = docs
              .where((doc) => !doc.data().toString().contains('emergencyType'))
              .toList();
        }

        if (docs.isEmpty) {
          return const Center(
            child: Text("No reports found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(10),
          children: docs.map((doc) {
            String reportId = doc.id;
            String emergencyType =
                widget.category == "Other" ? "Other" : doc["emergencyType"];
            GeoPoint location = doc["location"];
            Timestamp timestamp = doc["timestamp"];
            String userId = doc["userId"];

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

                    // Incident Image (only if available)
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

                    // Description (only if available)
                    if (description != null && description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),

                    // Emergency Type (only for non-Other categories)
                    if (widget.category != "Other")
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              "Emergency: $emergencyType",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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

                    // Mark as Completed (only for Active reports)
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
          title: Text(
            "${widget.category} Reports",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          elevation: 0,
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
          buildReportList("active"), // Active Reports Tab
          buildReportList("completed"), // Completed Reports Tab
        ],
      ),
    );
  }
}
