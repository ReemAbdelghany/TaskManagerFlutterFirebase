import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:task_manager/models/task_model.dart';
import 'package:task_manager/screens/task_list_screen.dart';
import 'package:task_manager/utils/file_storage.dart';
import 'dart:async';

class AddTaskScreen extends StatefulWidget {
  final Function(TaskModel) onTaskAdded;

  const AddTaskScreen({Key? key, required this.onTaskAdded}) : super(key: key);

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  var taskController = TextEditingController();
  bool isOnline = true;
  late StreamSubscription<ConnectivityResult> connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Listen to connectivity changes
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
    });
  }

  @override
  void dispose() {
    // Dispose of the connectivity subscription
    connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                hintText: 'Task Name',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                String taskName = taskController.text.trim();
                if (taskName.isEmpty) {
                  Fluttertoast.showToast(msg: 'Please provide task name');
                  return;
                }

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  String uid = user.uid;
                  int dt = DateTime.now().millisecondsSinceEpoch;
                  String taskId = DateTime.now().millisecondsSinceEpoch.toString();
                  TaskModel task = TaskModel(taskId: taskId, taskName: taskName, dt: dt);

                  // Save task locally
                  List<TaskModel> tasks = await FileStorage.readTasks();
                  tasks.add(task);
                  await FileStorage.saveTasks(tasks);

                  // Notify the parent widget and update UI
                  widget.onTaskAdded(task);

                  if (isOnline) {
                    // Synchronize with Firebase
                    DatabaseReference taskRef = FirebaseDatabase.instance.reference().child('tasks').child(uid);
                    await taskRef.child(task.taskId).set(task.toMap());
                  } else {
                    // Queue the task addition for later synchronization
                    await queueOperation('add', task);
                    Fluttertoast.showToast(msg: 'Task saved locally. It will be synchronized when online.');
                  }

                  // Navigate back to TaskListScreen regardless of online status
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  /// Queues an operation for later synchronization when online.
  Future<void> queueOperation(String type, TaskModel task) async {
    List<Map<String, dynamic>> operations = await FileStorage.readOperationQueue();
    operations.add({'type': type, 'task': task.toMap()});
    await FileStorage.saveOperationQueue(operations);
  }
}
