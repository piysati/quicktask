import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:task_manager_app/tasks/data/local/data_sources/tasks_data_provider.dart';
import 'package:task_manager_app/tasks/data/local/model/task_model.dart';

class TaskRepository{
  final TaskDataProvider taskDataProvider;

  TaskRepository({required this.taskDataProvider});

  Future<void> addNewTask(TaskModel taskModel) async {
      String taskName = taskModel.title;
      String description = taskModel.description;
      DateTime? dueDate = taskModel.stopDateTime;
      try {

        ParseObject taskObject = ParseObject("Task")
          ..set("taskName", taskName)
          ..set("description", description)
          ..set("dueDate", dueDate);

        await taskObject.save();

      } catch (e) {
        // Handle error
        print('Error adding task: $e');
      }
  }

  Future<List<TaskModel>> fetchTasks() async {
    final query = QueryBuilder(ParseObject('Task'));
    try {
      final response = await query.query();
      if (response.results != null) {
        return response.results!.map((parseObject) {
          var dueDate = parseObject.get<DateTime>('dueDate');
          print('due date $dueDate');
          return TaskModel(
            id: parseObject.objectId!,
            title: parseObject.get<String>('taskName')!,
            description: parseObject.get<String>('description')!,
            startDateTime: DateTime.now(),
            stopDateTime: parseObject.get<DateTime>('dueDate') ?? DateTime.now(),
            completed: parseObject.get<bool>('completed') ?? false,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }

  Future<List<TaskModel>> updateUserTask(TaskModel taskModel) async {
    try {

      final parseObject = ParseObject('Task')
        ..objectId = taskModel.id // Set the objectId of the Task object
        ..set<String>('taskName', taskModel.title)
        ..set<String>('description', taskModel.description)
        ..set<bool>('completed', taskModel.completed)
        ..set<DateTime>('dueDate', taskModel.stopDateTime ?? DateTime.now());

      final response = await parseObject.save();

      if (response.success) {
        final updatedTasks = await fetchTasks(); // Assuming you have a fetchTasks() function to fetch tasks
        return updatedTasks;
      } else {
        throw Exception(response.error!.message);
      }
    } catch (exception) {
      throw Exception('Failed to update task: $exception');
    }
  }

  Future<List<TaskModel>> deleteUserTask(TaskModel taskModel) async {
    try {

      final parseObject = ParseObject('Task')..objectId = taskModel.id;

      final response = await parseObject.delete();
      if (!response.success) {
        throw Exception(response.error!.message);
      }

      final updatedTasks = await fetchTasks(); // Assuming you have a fetchTasks() function to fetch tasks
      return updatedTasks;
    } catch (exception) {

      throw Exception('Failed to delete task: $exception');
    }
  }


}