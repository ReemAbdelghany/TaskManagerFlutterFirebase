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

  _getUserDetails() async {
    DatabaseEvent event = await userRef!.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      userModel = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      setState(() {});
    }
  }

  _pickImageFromGallery(ImageSource source) async {
    XFile? file = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (file == null) return;

    imageFile = File(file.path);
    showLocalFile = true;
    setState(() {});

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

      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(userModel!.uid);

      await userRef.update({
        'profileImage': profileImageUrl,
      });

      progressDialog.dismiss();
    } catch (e) {
      progressDialog.dismiss();
      print(e.toString());
    }
  }

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
    const purpleColor = Color(0xFF5727B0);

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
        'Profile',
        style: TextStyle(color: Colors.white),
    ),
    ),
    body: userModel == null
    ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
    Center(
    child: Column(
    children: [
    CircleAvatar(
    radius: 60,
    backgroundImage: showLocalFile == false
    ? NetworkImage(userModel!.profileImage == ''
    ? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQGrQoGh518HulzrSYOTee8UO517D_j6h4AYQ&usqp=CAU'
        : userModel!.profileImage)
        : FileImage(imageFile!) as ImageProvider,
    ),
    IconButton(
    icon: const Icon(Icons.camera_alt, color: Colors.white),
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
    });
    },
    ),
    ],
    ),
    ),
    const SizedBox(height: 20),
    Card(
    color: Colors.grey[900],
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    userModel!.fullName,
    style: const TextStyle(
    fontSize: 22,
    color: Colors.white,
    fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    Text(
    userModel!.email,
    style: const TextStyle(
    fontSize: 18, color: Colors.white70),
    ),
    const SizedBox(height: 10),
    Text(
    'Joined ${getHumanReadableDate(userModel!.dt)}',
    style: const TextStyle(
    fontSize: 16, color: Colors.white70),
    ),
    ],
    ),
    ),
    ),
    const SizedBox(height: 20),
    Card(
    color: Colors.grey[900],
    child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Bio',
    style: TextStyle(
    fontSize: 18,
    color: purpleColor,
    fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    const Text(
    'This is a sample bio. You can add your bio here.',
    style: TextStyle(fontSize: 16, color: Colors.white),
    ),
    ],
    ),
    ),
    ),
    const SizedBox(height: 20),
    Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Expanded(
    child: Card(
    color: Colors.grey[900],
    child: Padding(
    padding: const EdgeInsets.all(8.0), // Updated padding here
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text(
    'Friends (3)',
    style: TextStyle(
    fontSize: 18,
    color: purpleColor,
    fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0), // Adjust vertical padding
    child: ListTile(
    leading: const Icon(Icons.person,
    color: Colors.white),
    title: const Text(
    'Hana',
      style: TextStyle(color: Colors.white,
        fontSize: 13,),
    ),
    ),
    ),
    Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0), // Adjust vertical padding
    child: ListTile(
    leading: const Icon(Icons.person,
    color: Colors.white),
    title: const Text(
      'Jessie',
      style: TextStyle(color: Colors.white,
        fontSize: 13,),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    ),
      const SizedBox(width: 10),
      Expanded(
        child: Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Updated padding here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Drawings',
                  style: TextStyle(
                      fontSize: 18,
                      color: purpleColor,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0), // Adjust vertical padding
                  child: ListTile(
                    leading: const Icon(Icons.brush,
                        color: Colors.white),
                    title: const Text(
                      'Drawing1',
                      style: TextStyle(color: Colors.white,
                        fontSize: 13,),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0), // Adjust vertical padding
                  child: ListTile(
                    leading: const Icon(Icons.brush,
                        color: Colors.white),
                    title: const Text(
                      'Drawing2',
                      style: TextStyle(color: Colors.white,
                        fontSize: 13,),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    ),
    ],
    ),
    ),
    ),
    );
  }

  String getHumanReadableDate(int dt) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dt);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}

