import 'package:emergency_app/UI/Colors/colors.dart';
import 'package:emergency_app/UI/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../provider/theme_provider.dart';
import '../../services/notification_service.dart';

class ContactsScreen extends StatefulWidget {
  final bool fromSOS;
  final String? emergencyType;
  const ContactsScreen({super.key, this.fromSOS = false, this.emergencyType});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  void addContact(String name, String phoneNumber) async {
    // First check if this is the user's own number
    final currentUserDoc =
        await _firestore.collection('users').doc(userId).get();
    final currentUserPhone = currentUserDoc.data()?['phone'];
    final currentUserContacts = List<Map<String, dynamic>>.from(
        currentUserDoc.data()?['emergencyContacts'] ?? []);

    // Check if number is already saved as emergency contact
    if (currentUserContacts.any((contact) => contact['phone'] == phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This number is already saved as an emergency contact'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (phoneNumber == currentUserPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add your own number as an emergency contact'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? docId;
    final querySnapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phoneNumber)
        .get();
    print("This is the querysnap ${querySnapshot.docs}");
    if (querySnapshot.docs.isNotEmpty) {
      docId = querySnapshot.docs.first.id;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This phone number is not registered in the app'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await _firestore.collection('users').doc(userId).update({
      'emergencyContacts': FieldValue.arrayUnion([
        {'name': name, 'phone': phoneNumber, 'docId': docId}
      ])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void showAddContactDialog() {
    String name = '';
    String phoneNumber = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final dialogBackgroundColor =
            themeProvider.isDarkMode ? Colors.grey[850] : Colors.white;
        final dialogTextColor =
            themeProvider.isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          title: Text('Add Contact', style: TextStyle(color: dialogTextColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: dialogTextColor)),
                onChanged: (value) {
                  name = value;
                },
              ),
              TextField(
                decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: dialogTextColor)),
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
              child: Text(
                'Cancel',
                style: TextStyle(color: dialogTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                addContact(name, phoneNumber);
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: TextStyle(color: dialogTextColor),
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

  Future<void> deleteContact(Map<String, String> contact) async {
    await _firestore.collection('users').doc(userId).update({
      'emergencyContacts': FieldValue.arrayRemove([contact])
    });
  }

  void sendEmergencyNotification(String docId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['name'] ?? 'Emergency Contact';


      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await NotificationService.sendEmergencyNotificationToUser(
        recipientDocId: docId,
        senderName: userName,
        emergencyType: widget.emergencyType ?? 'Emergency',
        latitude: position.latitude,
        longitude: position.longitude,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emergency alert sent successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send emergency alert')),
      );
      print('Error sending emergency notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor =
        themeProvider.isDarkMode ? Colors.black : Colors.white;
    final appBarColor =
        themeProvider.isDarkMode ? Colors.grey[850] : primaryColor;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor =
        themeProvider.isDarkMode ? Colors.white70 : Colors.grey;

    return WillPopScope(
      onWillPop: () async {
        if (widget.fromSOS) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: appBarColor,
          title: Text(
            'Add Emergency Contacts',
            style: TextStyle(color: textColor),
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
                final contact =
                    emergencyContacts[index] as Map<String, dynamic>;
                final String name = contact['name'] ?? '';
                final String phone = contact['phone'] ?? '';

                return Card(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]
                      : Colors.white,
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
                      name,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : primaryColor,
                      ),
                    ),
                    subtitle: Text(
                      phone,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: subtitleColor,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.fromSOS) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.call,
                              color: primaryColor,
                              size: 30,
                            ),
                            onPressed: () {
                              makeCall(phone);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.message,
                              color: primaryColor,
                              size: 30,
                            ),
                            onPressed: () {
                              final String? docId = contact['docId'];
                              if (docId != null) {
                                sendEmergencyNotification(docId);
                              } else {
                                print('No user found with this phone number.');
                              }
                            },
                          ),
                        ],
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 30,
                          ),
                          onPressed: () {
                            deleteContact(Map<String, String>.from(contact));
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
          backgroundColor:
              themeProvider.isDarkMode ? Colors.grey : primaryColor,
          child: const Icon(
            Icons.contact_emergency_rounded,
            color: Colors.white,
          ),
          elevation: 10.0,
          tooltip: 'Add Contact',
        ),
      ),
    );
  }
}
