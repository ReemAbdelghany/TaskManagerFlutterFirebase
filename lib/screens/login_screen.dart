import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:task_manager/screens/admin_view_screen.dart'; // Import the admin view screen
import 'package:task_manager/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Please'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
              ),
            ),
            const SizedBox(height: 10,),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
            ),
            const SizedBox(height: 10,),
            ElevatedButton(
              onPressed: () async {
                var email = emailController.text.trim();
                var password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) {
                  Fluttertoast.showToast(msg: 'Please fill all fields');
                  return;
                }

                try {
                  FirebaseAuth auth = FirebaseAuth.instance;
                  UserCredential userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);

                  if (userCredential.user != null) {
                    // Check if the user is an admin
                    bool isAdmin = await checkAdminStatus(userCredential.user!.uid);

                    if (isAdmin) {
                      // Navigate to AdminUserListScreen if the user is an admin
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                        return const AdminUserListScreen();
                      }));
                    } else {
                      // Navigate to another screen if the user is not an admin
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                        return const TaskListScreen(); // Replace OtherScreen with your desired screen for non-admin users
                      }));
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'user-not-found') {
                    Fluttertoast.showToast(msg: 'User not found');
                  } else if (e.code == 'wrong-password') {
                    Fluttertoast.showToast(msg: 'Wrong password');
                  }
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Something went wrong');
                }
              },
              child: const Text('Login'),
            ),
            const SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Not Registered Yet'),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return const SignUpScreen();
                    }));
                  },
                  child: const Text('Register Now'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<bool> checkAdminStatus(String userId) async {
    DatabaseReference adminRef = FirebaseDatabase.instance.reference().child('admins').child(userId);
    DataSnapshot snapshot = await adminRef.get();
    if (snapshot.value != null) {
      Map<String, dynamic>? userData = snapshot.value as Map<String, dynamic>?; // Cast to Map<String, dynamic> or null
      if (userData != null) {
        bool isAdmin = userData['isAdmin'] ?? false; // Default to false if isAdmin is not set
        return isAdmin;
      }
    }
    return false; // Default to false if admin data not found
  }
}
