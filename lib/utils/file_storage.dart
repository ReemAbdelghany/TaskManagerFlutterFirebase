import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:task_manager/models/task_model.dart';

class FileStorage {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/tasks.json');
  }

  static Future<File> get _operationQueueFile async {
    final path = await _localPath;
    return File('$path/operation_queue.json');
  }

  static Future<File> saveTasks(List<TaskModel> tasks) async {
    final file = await _localFile;
    String json = jsonEncode(tasks.map((task) => task.toMap()).toList());
    return file.writeAsString(json);
  }

  static Future<List<TaskModel>> readTasks() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      List<dynamic> json = jsonDecode(contents);
      return json.map((task) => TaskModel.fromMap(task)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<File> saveOperationQueue(List<Map<String, dynamic>> operations) async {
    final file = await _operationQueueFile;
    String json = jsonEncode(operations);
    return file.writeAsString(json);
  }

  static Future<List<Map<String, dynamic>>> readOperationQueue() async {
    try {
      final file = await _operationQueueFile;
      String contents = await file.readAsString();
      List<dynamic> json = jsonDecode(contents);
      return List<Map<String, dynamic>>.from(json);
    } catch (e) {
      return [];
    }
  }
}
