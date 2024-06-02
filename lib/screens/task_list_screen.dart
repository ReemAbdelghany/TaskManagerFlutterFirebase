import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/models/task_model.dart';
import 'package:task_manager/screens/login_screen.dart';
import 'package:task_manager/screens/profile_screen.dart';
import 'package:task_manager/screens/update_task_screen.dart';
import 'package:task_manager/screens/add_task_screen.dart';
import 'package:task_manager/utils/file_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  User? user;
  List<TaskModel> tasks = [];
  bool isOnline = true;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    loadTasks();
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
      if (isOnline) {
        synchronizeTasks();
      }
    });
  }

  @override
  void dispose() {
    connectivitySubscription.cancel(); // Cancel the subscription
    super.dispose();
  }

  /// Loads tasks from local storage and synchronizes them if online.
  Future<void> loadTasks() async {
    tasks = await FileStorage.readTasks();
    setState(() {});
    if (isOnline) {
      await synchronizeTasks();
    }
  }

  /// Synchronizes local tasks with the Firebase database.
  Future<void> synchronizeTasks() async {
    if (user != null) {
      DatabaseReference taskRef = FirebaseDatabase.instance.reference().child('tasks').child(user!.uid);

      // Upload all local tasks to Firebase
      for (var task in tasks) {
        await taskRef.child(task.taskId).set(task.toMap());
      }

      // Process queued operations
      List<Map<String, dynamic>> operations = await FileStorage.readOperationQueue();
      for (var operation in operations) {
        String type = operation['type'];
        TaskModel task = TaskModel.fromMap(operation['task']);
        if (type == 'add' || type == 'update') {
          await taskRef.child(task.taskId).set(task.toMap());
        } else if (type == 'delete') {
          await taskRef.child(task.taskId).remove();
        }
      }

      // Clear the queue after synchronization
      await FileStorage.saveOperationQueue([]);
    }
  }

  /// Queues an operation to be performed when the app goes online.
  Future<void> queueOperation(String type, TaskModel task) async {
    List<Map<String, dynamic>> operations = await FileStorage.readOperationQueue();
    operations.add({'type': type, 'task': task.toMap()});
    await FileStorage.saveOperationQueue(operations);
  }

  /// Adds a new task locally and online if possible.
  Future<void> addTask(TaskModel task) async {
    tasks.add(task);
    await FileStorage.saveTasks(tasks);
    setState(() {});
    if (isOnline && user != null) {
      DatabaseReference taskRef = FirebaseDatabase.instance.reference().child('tasks').child(user!.uid);
      await taskRef.child(task.taskId).set(task.toMap());
    } else {
      await queueOperation('add', task);
    }
  }

  /// Deletes a task locally and online if possible.
  Future<void> deleteTask(TaskModel task) async {
    tasks.remove(task); // Remove the task from the local list
    await FileStorage.saveTasks(tasks); // Save the updated task list locally
    setState(() {}); // Update the UI

    if (isOnline && user != null) {
      DatabaseReference taskRef = FirebaseDatabase.instance.reference().child('tasks').child(user!.uid);
      await taskRef.child(task.taskId).remove(); // Remove the task from the database
    } else {
      await queueOperation('delete', task); // Queue the delete operation if offline
    }
  }

  /// Updates a task locally and online if possible.
  Future<void> updateTask(TaskModel updatedTask) async {
    int index = tasks.indexWhere((task) => task.taskId == updatedTask.taskId);
    if (index != -1) {
      tasks[index] = updatedTask;
      await FileStorage.saveTasks(tasks);
      setState(() {});
      if (isOnline && user != null) {
        DatabaseReference taskRef = FirebaseDatabase.instance.reference().child('tasks').child(user!.uid);
        await taskRef.child(updatedTask.taskId).update(updatedTask.toMap());
      } else {
        await queueOperation('update', updatedTask);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
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
              showDialog(context: context, builder: (ctx) {
                return AlertDialog(
                  title: const Text('Confirmation !!!'),
                  content: const Text('Are you sure to Log Out ?'),
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
              });
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final task = await Navigator.of(context).push(MaterialPageRoute<TaskModel>(builder: (context) {
            return AddTaskScreen(onTaskAdded: addTask);
          }));

          // If a task was added, update the task list
          if (task != null) {
            addTask(task);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No Tasks Added Yet'))
          : Padding(
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
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          showDialog(context: context, builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Confirmation !!!'),
                              content: const Text('Are you sure to delete ?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await deleteTask(task);
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            );
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                            return UpdateTaskScreen(task: task, onTaskUpdated: updateTask);
                          }));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Converts a timestamp to a human-readable date format.
  String getHumanReadableDate(int dt) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(dt);
    return DateFormat('dd MMM yyyy').format(dateTime);
  }
}
