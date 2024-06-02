import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:task_manager/screens/login_screen.dart';
import 'package:task_manager/screens/profile_screen.dart';
import 'package:task_manager/models/user_model.dart'; // Import the UserModel

/// Represents the screen where an admin can view and manage the list of users.
class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({Key? key});

  @override
  AdminUserListScreenState createState() => AdminUserListScreenState();
}

class AdminUserListScreenState extends State<AdminUserListScreen> {
  DatabaseReference? userRef;

  /// Initialize the screen and set the reference to the 'users' node in Firebase.
  @override
  void initState() {
    userRef = FirebaseDatabase.instance.reference().child('users');
    super.initState();
  }

  /// Deletes a user from Firebase by their UID.
  void deleteUser(String uid) {
    userRef!.child(uid).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $error')),
      );
    });
  }

  /// Builds the UI for the admin user list screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin page'),
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
            var snapshot2 = snapshot.data!.snapshot.value;
            if (snapshot2 == null) {
              return const Center(child: Text('No Users Found'));
            }

            Map<String, dynamic> map = Map<String, dynamic>.from(snapshot2 as Map);
            var users = <UserModel>[];

            for (var userMap in map.values) {
              users.add(UserModel.fromMap(Map<String, dynamic>.from(userMap)));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index].fullName),
                  subtitle: Text('Email: ${users[index].email}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      deleteUser(users[index].uid);
                    },
                  ),
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
