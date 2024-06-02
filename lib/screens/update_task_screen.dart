import 'package:flutter/material.dart';
import 'package:task_manager/models/task_model.dart';

class UpdateTaskScreen extends StatefulWidget {
  final TaskModel task; // The task to be updated
  final Function(TaskModel) onTaskUpdated; // Callback function to notify the parent widget

  const UpdateTaskScreen({Key? key, required this.task, required this.onTaskUpdated}) : super(key: key);

  @override
  State<UpdateTaskScreen> createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  var taskController = TextEditingController(); // Controller for the task name text field

  @override
  void initState() {
    super.initState();
    taskController.text = widget.task.taskName; // Set the initial value of the text field to the current task name
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: taskController, // Connect the controller to the text field
              decoration: const InputDecoration(
                hintText: 'Task Name',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                String updatedTaskName = taskController.text.trim(); // Get the updated task name from the text field

                if (updatedTaskName.isEmpty) {
                  return; // Do nothing if the updated task name is empty
                }

                // Create a new TaskModel object with the updated information
                TaskModel updatedTask = TaskModel(
                  taskId: widget.task.taskId,
                  taskName: updatedTaskName,
                  dt: widget.task.dt,
                );

                // Call the callback function to notify the parent widget of the updated task
                widget.onTaskUpdated(updatedTask);

                // Close the update task screen
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
