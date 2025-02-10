import 'dart:io';

import 'package:emergency_app/UI/Colors/colors.dart';
import 'package:emergency_app/UI/screens/home_screen.dart';
import 'package:emergency_app/provider/theme_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../widgets/custom_textfield.dart';

class MyprofileScreen extends StatefulWidget {
  const MyprofileScreen({super.key});

  @override
  State<MyprofileScreen> createState() => _MyprofileScreenState();
}

class _MyprofileScreenState extends State<MyprofileScreen> {
  final TextEditingController nameController = TextEditingController(text: "");
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String? gender;
  XFile? profileImage;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            if (nameController.text.isEmpty) {
              nameController.text = userData['name'] ?? '';
            }
            if (phoneController.text.isEmpty) {
              phoneController.text = userData['phone']?.toString() ?? '';
            }
            if (dobController.text.isEmpty) {
              dobController.text = userData['dob'] ?? '';
            }
            if (addressController.text.isEmpty) {
              addressController.text = userData['address'] ?? '';
            }
            if (gender == null) {
              gender = userData['gender'] ?? 'Male';
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: selectProfileImage,
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 35,
                                  color: Colors.white,
                                )
                              : ClipOval(
                                  child: Image.file(
                                    File(profileImage!.path),
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "My Avatar",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 5),
                          Text("Upload a photo of yourself")
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 50),
                  const Text("Name"),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: nameController,
                    hintText: '',
                    prefixIcon: Icons.person,
                    isPassword: false,
                  ),
                  const SizedBox(height: 20),
                  const Text("Phone Number"),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: phoneController,
                    hintText: 'Enter your phone number',
                    prefixIcon: Icons.phone,
                    isPassword: false,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty &&
                          !RegExp(r'^\d+$').hasMatch(value)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Only numeric input is allowed')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Date of Birth"),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => selectDate(context),
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: dobController,
                        hintText: 'Select your date of birth',
                        prefixIcon: Icons.calendar_today,
                        isPassword: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Address"),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: addressController,
                    hintText: 'Enter your address',
                    prefixIcon: Icons.location_on,
                    isPassword: false,
                  ),
                  const SizedBox(height: 20),
                  const Text("Gender"),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1.5),
                      borderRadius: BorderRadius.circular(14.88),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Select your gender'),
                        value: gender,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: <String>['Male', 'Female', 'Other']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            gender = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        await updateUserData();
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        dobController.text =
            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";
      });
    }
  }

  Future<void> uploadProfileImage(XFile image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'profile_images/${FirebaseAuth.instance.currentUser!.uid}.jpg');

      await storageRef.putFile(File(image.path));

      String imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImage': imageUrl,
      });
      setState(() {
        profileImage = image;
      });
    } catch (e) {
      print("Error uploading profile image: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to upload image.')));
    }
  }

  Future<void> selectProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      await uploadProfileImage(image);
    }
  }

  Future<void> updateUserData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'name': nameController.text,
        'phone': phoneController.text,
        'dob': dobController.text,
        'address': addressController.text,
        'gender': gender,
        'profileImage': profileImage?.path,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print("Error updating user data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }
}
