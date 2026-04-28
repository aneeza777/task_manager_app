import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'tasks';

  // Get current User ID if logged in
  String? get _userId {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuth.instance.currentUser?.uid;
    }
    return null;
  }

  // Load tasks from SharedPreferences
  Future<List<Task>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Use user-specific key if logged in, else default key
    final String key = _userId != null ? '$_tasksKey-$_userId' : _tasksKey;
    final String? tasksJson = prefs.getString(key);

    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }

  // Save tasks to SharedPreferences and Firebase
  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(tasks.map((e) => e.toJson()).toList());
    
    final String key = _userId != null ? '$_tasksKey-$_userId' : _tasksKey;
    await prefs.setString(key, encoded);

    // Sync to Firebase
    _syncWithFirebase(tasks);
  }

  Future<void> _syncWithFirebase(List<Task> tasks) async {
    final uid = _userId;
    if (uid == null) return; // Only sync if logged in

    try {
      final collection = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks');
          
      // A simple sync: update all items
      for (var task in tasks) {
        await collection.doc(task.id).set(task.toJson());
      }
    } catch (e) {
      print("Firebase sync error: $e");
    }
  }

  Future<void> _deleteFromFirebase(String taskId) async {
    final uid = _userId;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print("Firebase delete error: $e");
    }
  }

  Future<List<Task>> addTask(Task task) async {
    final tasks = await loadTasks();
    tasks.add(task);
    await saveTasks(tasks);
    return tasks;
  }

  Future<List<Task>> updateTask(Task updatedTask) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
    return tasks;
  }

  Future<List<Task>> toggleTaskComplete(String taskId) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(isCompleted: !tasks[index].isCompleted);
      await saveTasks(tasks);
    }
    return tasks;
  }

  Future<List<Task>> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await saveTasks(tasks);
    await _deleteFromFirebase(taskId);
    return tasks;
  }
}
