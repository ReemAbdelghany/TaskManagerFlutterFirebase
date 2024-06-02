import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:task_manager/screens/admin_view_screen.dart';
import 'package:task_manager/screens/signup_screen.dart';
import 'package:task_manager/screens/task_list_screen.dart';

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
        title: const Text('Login'),
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
                    // Retrieve user type from Firebase
                    int userTypeId = await getUserTypeId(userCredential.user!.uid);

                    if (userTypeId == 1) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                        return const AdminUserListScreen(); // Navigate to admin user list screen
                      }));
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                        return const TaskListScreen();
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

  /// Retrieves the user type ID from Firebase.
  Future<int> getUserTypeId(String userId) async {
    DatabaseReference userTypeRef = FirebaseDatabase.instance.reference().child('users').child(userId).child('UserTypeId');
    DataSnapshot snapshot = await userTypeRef.get();
    return snapshot.value != null ? int.parse(snapshot.value.toString()) : 1; // Default to 1 if not found
  }
}
