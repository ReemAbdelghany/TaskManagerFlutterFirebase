import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/models/task_model.dart';
import 'package:task_manager/screens/login_screen.dart';
import 'package:task_manager/screens/profile_screen.dart';
import 'package:task_manager/screens/update_task_screen.dart';

import 'add_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {

  User? user;
  DatabaseReference? taskRef;

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      taskRef = FirebaseDatabase.instance.reference().child('tasks').child(user!.uid);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        actions: [
          IconButton(onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return const ProfileScreen();
            }));
          }, icon: const Icon(Icons.person)),
          IconButton(onPressed: () {
            showDialog(context: context, builder: (ctx) {
              return AlertDialog(
                title: const Text('Confirmation !!!'),
                content: const Text('Are you sure to Log Out ? '),
                actions: [
                  TextButton(onPressed: () {
                    Navigator.of(ctx).pop();
                  }, child: const Text('No')),
                  TextButton(onPressed: () {
                    Navigator.of(ctx).pop();
                    FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                      return const LoginScreen();
                    }));
                  }, child: const Text('Yes')),
                ],
              );
            });
          }, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return const AddTaskScreen();
          }));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: taskRef?.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.hasError) {
            var event = snapshot.data as DatabaseEvent;
            var snapshot2 = event.snapshot.value;
            if (snapshot2 == null) {
              return const Center(child: Text('No Tasks Added Yet'));
            }

            Map<String, dynamic> map = Map<String, dynamic>.from(snapshot2 as Map);
            var tasks = <TaskModel>[];

            for (var taskMap in map.values) {
              TaskModel taskModel = TaskModel.fromMap(Map<String, dynamic>.from(taskMap as Map));
              tasks.add(taskModel);
            }

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  TaskModel task = tasks[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(task.taskName),
                        Text(getHumanReadableDate(task.dt)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.delete), onPressed: () {
                              showDialog(context: context, builder: (ctx) {
                                return AlertDialog(
                                  title: const Text('Confirmation !!!'),
                                  content: const Text('Are you sure to delete ? '),
                                  actions: [
                                    TextButton(onPressed: () {
                                      Navigator.of(ctx).pop();
                                    }, child: const Text('No')),
                                    TextButton(onPressed: () async {
                                      if (taskRef != null) {
                                        await taskRef!.child(task.taskId).remove();
                                      }
                                      Navigator.of(ctx).pop();
                                    }, child: const Text('Yes')),
                                  ],
                                );
                              });
                            }),
                            IconButton(icon: const Icon(Icons.edit), onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                                return UpdateTaskScreen(task: task);
                              }));
                            })
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  String getHumanReadableDate(int dt) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dt);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
