import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:ndialog/ndialog.dart';
import 'package:task_manager/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  UserModel? userModel;
  DatabaseReference? userRef;

  File? imageFile;
  bool showLocalFile = false;

  // Fetch user details from Firebase database
  _getUserDetails() async {
    DatabaseEvent event = await userRef!.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      userModel = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      setState(() {});
    }
  }

  // Pick an image from the gallery
  _pickImageFromGallery(ImageSource source) async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (file == null) return;

    imageFile = File(file.path);
    showLocalFile = true;
    setState(() {});

    // Upload the image to Firebase storage
    ProgressDialog progressDialog = ProgressDialog(
      context,
      title: const Text('Uploading !!!'),
      message: const Text('Please wait'),
    );
    progressDialog.show();
    try {
      var fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';

      UploadTask uploadTask = FirebaseStorage.instance.ref().child('profile_images').child(fileName).putFile(imageFile!);

      TaskSnapshot snapshot = await uploadTask;

      String profileImageUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profile image URL in the database
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userModel!.uid);

      await userRef.update({
        'profileImage':profileImageUrl,
      });

      progressDialog.dismiss();
    } catch (e) {
      progressDialog.dismiss();
      print(e.toString());
    }
  }

  // Pick an image from the camera
  _pickImageFromCamera(ImageSource source) async {
    XFile? xFile = await ImagePicker().pickImage(source: ImageSource.camera);

    if (xFile == null) return;

    final tempImage = File(xFile.path);

    imageFile = tempImage;
    showLocalFile = true;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userRef = FirebaseDatabase.instance.reference().child('users').child(user!.uid);
    }

    _getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                // Display user profile image
                CircleAvatar(
                  radius: 80,
                  backgroundImage: showLocalFile == false
                      ? NetworkImage(
                      userModel!.profileImage == ''
                          ? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGrQoGh518HulzrSYOTee8UO517D_j6h4AYQ&usqp=CAU'
                          : userModel!.profileImage
                  )
                      : FileImage(imageFile!) as ImageProvider,
                ),
                // Button to pick image from camera or gallery
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.image),
                                  title: const Text('From Gallery'),
                                  onTap: () {
                                    _pickImageFromGallery(ImageSource.gallery);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('From Camera'),
                                  onTap: () {
                                    _pickImageFromCamera(ImageSource.camera);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                    );
                  },
                ),
              ],
            ),
            // Display user details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        userModel!.fullName,
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        userModel!.email,
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        'Joined ${getHumanReadableDate(userModel!.dt)}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Convert timestamp to human-readable date format
  String getHumanReadableDate(int dt) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dt);

    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
