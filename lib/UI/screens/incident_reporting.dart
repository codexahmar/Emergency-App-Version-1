import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../provider/theme_provider.dart';
import '../Colors/colors.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({super.key});

  @override
  State<IncidentReportingScreen> createState() =>
      _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  final TextEditingController descriptionController = TextEditingController();
  XFile? selectedImage;
  bool isSubmitting = false;

  Future<void> pickImage() async {
    final ImagePicker imagePicker = ImagePicker();
    final XFile? pickedImageFile =
        await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedImageFile != null) {
      setState(() {
        selectedImage = pickedImageFile;
      });
    }
  }

  String getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.uid : "Unknown User";
  }

  Future<Map<String, double>> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return {"lat": 0.0, "lng": 0.0};
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      return {"lat": position.latitude, "lng": position.longitude};
    } catch (e) {
      print("Error getting location: $e");
      return {"lat": 0.0, "lng": 0.0};
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref =
          FirebaseStorage.instance.ref().child("incident_images/$fileName.jpg");
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> submitReport() async {
    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String userId = getCurrentUserId();

      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await uploadImage(File(selectedImage!.path));
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      DocumentReference incidentDoc =
          FirebaseFirestore.instance.collection("incidentReports").doc();

      await incidentDoc.set({
        "docId": incidentDoc.id,
        "description": descriptionController.text,
        "incidentPic": imageUrl ?? "",
        "userId": userId,
        "timestamp": FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
        "status": "active"
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incident reported successfully.")),
      );

      setState(() {
        descriptionController.clear();
        selectedImage = null;
      });
    } catch (e) {
      print("Error submitting report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to report incident.")),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Incident Reporting',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode
                    ? Colors.grey[850]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                ),
              ),
              child: TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Describe the incident',
                  labelStyle: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white54
                        : Colors.black54,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'Take a Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            selectedImage != null
                ? Image.file(
                    File(selectedImage!.path),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : const Text('No image selected.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: isSubmitting ? null : submitReport,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: isSubmitting ? Colors.grey : primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
