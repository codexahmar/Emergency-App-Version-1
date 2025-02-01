import 'package:emergency_app/UI/Colors/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Map<String, String>> contacts = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  // print("THis is current logged in user docID $userId");

  void addContact(String name, String phoneNumber) {
    setState(() {
      contacts.add({'name': name, 'phone': phoneNumber});
    });

    // Update Firestore
    _firestore.collection('users').doc(userId).update({
      'emergencyContacts': FieldValue.arrayUnion([
        {'name': name, 'phone': phoneNumber}
      ])
    });
  }

  void showAddContactDialog() {
    String name = '';
    String phoneNumber = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  phoneNumber = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                addContact(name, phoneNumber);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> makeCall(String phoneNumber) async {
    final Uri phoneUrl = Uri(scheme: 'tel', path: phoneNumber);

    if (await canLaunch(phoneUrl.toString())) {
      await launch(phoneUrl.toString());
    } else {
      throw 'Could not launch dialer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Add Emergency Contacts',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 10.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return Center(child: Text('No contacts found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> emergencyContacts =
              data['emergencyContacts'] ?? [];

          return ListView.builder(
            itemCount: emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = emergencyContacts[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.all(12.0),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 20.0,
                  ),
                  title: Text(
                    contact['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  subtitle: Text(
                    contact['phone'] ?? '',
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.call,
                          color: primaryColor,
                          size: 30,
                        ),
                        onPressed: () {
                          makeCall(contact['phone'] ?? '');
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: primaryColor,
                          size: 30,
                        ),
                        onPressed: () {
                          // Implement message functionality (e.g., open messaging app)
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddContactDialog,
        backgroundColor: primaryColor,
        child: const Icon(
          Icons.contact_emergency_rounded,
          color: Colors.white,
        ),
        elevation: 10.0,
        tooltip: 'Add Contact',
      ),
    );
  }
}
