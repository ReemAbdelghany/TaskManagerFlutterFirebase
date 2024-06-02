import 'dart:convert'; // Importing dart:convert library to handle JSON encoding and decoding
import 'dart:io'; // Importing dart:io library for file operations
import 'package:path_provider/path_provider.dart'; // Importing path_provider package to access device file system
import 'package:task_manager/models/task_model.dart'; // Importing TaskModel class

class FileStorage {
  // Method to get the local path for storing files asynchronously
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory(); // Getting application documents directory
    return directory.path; // Returning the path of the documents directory
  }

  // Method to get the local file for storing tasks asynchronously
  static Future<File> get _localFile async {
    final path = await _localPath; // Getting the local path
    return File('$path/tasks.json'); // Returning the file path for storing tasks
  }

  // Method to get the local file for storing operation queue asynchronously
  static Future<File> get _operationQueueFile async {
    final path = await _localPath; // Getting the local path
    return File('$path/operation_queue.json'); // Returning the file path for storing operation queue
  }

  // Method to save tasks to the local file asynchronously
  static Future<File> saveTasks(List<TaskModel> tasks) async {
    final file = await _localFile; // Getting the local file
    String json = jsonEncode(tasks.map((task) => task.toMap()).toList()); // Converting tasks to JSON string
    return file.writeAsString(json); // Writing JSON string to the file
  }

  // Method to read tasks from the local file asynchronously
  static Future<List<TaskModel>> readTasks() async {
    try {
      final file = await _localFile; // Getting the local file
      String contents = await file.readAsString(); // Reading file contents as a string
      List<dynamic> json = jsonDecode(contents); // Decoding JSON string to a dynamic list
      return json.map((task) => TaskModel.fromMap(task)).toList(); // Mapping dynamic list to TaskModel list
    } catch (e) {
      return []; // Returning an empty list if an error occurs
    }
  }

  // Method to save operation queue to the local file asynchronously
  static Future<File> saveOperationQueue(List<Map<String, dynamic>> operations) async {
    final file = await _operationQueueFile; // Getting the operation queue file
    String json = jsonEncode(operations); // Converting operations to JSON string
    return file.writeAsString(json); // Writing JSON string to the file
  }

  // Method to read operation queue from the local file asynchronously
  static Future<List<Map<String, dynamic>>> readOperationQueue() async {
    try {
      final file = await _operationQueueFile; // Getting the operation queue file
      String contents = await file.readAsString(); // Reading file contents as a string
      List<dynamic> json = jsonDecode(contents); // Decoding JSON string to a dynamic list
      return List<Map<String, dynamic>>.from(json); // Returning a list of maps
    } catch (e) {
      return []; // Returning an empty list if an error occurs
    }
  }
}
