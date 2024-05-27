import 'package:flutter/material.dart';
import 'package:task_manager/models/task_model.dart';

class UpdateTaskScreen extends StatefulWidget {
  final TaskModel task;
  final Function(TaskModel) onTaskUpdated;

  const UpdateTaskScreen({Key? key, required this.task, required this.onTaskUpdated}) : super(key: key);

  @override
  State<UpdateTaskScreen> createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  var taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    taskController.text = widget.task.taskName;
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
              controller: taskController,
              decoration: const InputDecoration(
                hintText: 'Task Name',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                String updatedTaskName = taskController.text.trim();

                if (updatedTaskName.isEmpty) {
                  return;
                }

                TaskModel updatedTask = TaskModel(
                  taskId: widget.task.taskId,
                  taskName: updatedTaskName,
                  dt: widget.task.dt,
                );

                widget.onTaskUpdated(updatedTask);
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
