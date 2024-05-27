import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:task_manager/screens/login_screen.dart';
import 'package:task_manager/screens/profile_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  AdminUserListScreenState createState() => AdminUserListScreenState();
}

class AdminUserListScreenState extends State<AdminUserListScreen> {
  User? user;
  DatabaseReference? userRef;
  bool isAdmin = false;

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      checkAdminStatus();
      userRef = FirebaseDatabase.instance.ref().child('users');
    }
    super.initState();
  }

  Future<void> checkAdminStatus() async {
    DatabaseReference adminRef = FirebaseDatabase.instance.ref().child('admins').child(user!.uid);
    DataSnapshot snapshot = await adminRef.get();
    setState(() {
      isAdmin = snapshot.exists;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return const ProfileScreen();
              }));
            },
            icon: const Icon(Icons.person),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Confirmation !!!'),
                    content: const Text('Are you sure to Log Out ? '),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                            return const LoginScreen();
                          }));
                        },
                        child: const Text('Yes'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
  stream: userRef!.onValue,
  builder: (context, snapshot) {
    if (snapshot.hasData && !snapshot.hasError) {
      var snapshot2 = snapshot.data!.snapshot.value; // Using snapshot.data!.snapshot.value directly
      if (snapshot2 == null) {
        return const Center(child: Text('No Users Found'));
      }

      Map<String, dynamic> map = Map<String, dynamic>.from(snapshot2 as Map);
      var users = <String>[]; // List to store user names or details

      for (var userMap in map.values) {
        // Extract user data and add to users list
        String userName = userMap['fullName'] ?? ''; // Adjust according to your data structure
        users.add(userName);
      }

      return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(users[index]),
            // Add more user details or actions if needed
          );
        },
      );
    } else if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  },
),
    );
  }
}
