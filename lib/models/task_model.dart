class TaskModel {
  String taskId;
  String taskName;
  int dt;

  TaskModel({
    required this.taskId,
    required this.taskName,
    required this.dt,
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'taskName': taskName,
      'dt': dt,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'],
      taskName: map['taskName'],
      dt: map['dt'],
    );
  }
}
