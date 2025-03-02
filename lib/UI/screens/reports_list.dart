import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportsListScreen extends StatelessWidget {
  final String category;

  const ReportsListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$category Reports")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("incidentReports")
            .where("category", isEqualTo: category)
            .orderBy("date", descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports found."));
          }
          return ListView(
            padding: const EdgeInsets.all(10),
            children: snapshot.data!.docs.map((doc) {
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading:
                      const Icon(Icons.warning, color: Colors.red, size: 40),
                  title: Text(doc["description"],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      "Reported by: ${doc["userId"]}\nDate: ${doc["date"].toDate()}"),
                  trailing: doc["incidentPic"] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.network(
                            doc["incidentPic"],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
