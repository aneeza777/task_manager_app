import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskService.loadTasks();
    setState(() {
      _tasks = tasks;
      _sortTasks();
      _isLoading = false;
    });
  }

  void _sortTasks() {
    // Sort: incomplete first, then by priority (high to low), then by date
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
      return 0;
    });
  }

  Future<void> _toggleTaskComplete(String id) async {
    final updatedTasks = await _taskService.toggleTaskComplete(id);
    _updateTasks(updatedTasks);
  }

  Future<void> _deleteTask(String id) async {
    final updatedTasks = await _taskService.deleteTask(id);
    _updateTasks(updatedTasks);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateTasks(List<Task> updatedTasks) {
    setState(() {
      _tasks = updatedTasks;
      _sortTasks();
    });
  }

  Future<void> _navigateToAddScreen([Task? existingTask]) async {
    final returnedTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(existingTask: existingTask),
      ),
    );

    if (returnedTask != null) {
      List<Task> updatedTasks;
      if (existingTask != null) {
        updatedTasks = await _taskService.updateTask(returnedTask);
      } else {
        updatedTasks = await _taskService.addTask(returnedTask);
      }
      _updateTasks(updatedTasks);
    }
  }

  Future<void> _logout() async {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2: return Colors.redAccent;
      case 1: return Colors.orangeAccent;
      case 0: default: return Colors.green;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 2: return "High";
      case 1: return "Medium";
      case 0: default: return "Low";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            if (user != null)
              Text(
                'Logged in as ${user.email}',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? _buildEmptyState(theme)
              : _buildTaskList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddScreen(),
        icon: const Icon(Icons.add),
        label: const Text("New Task"),
        elevation: 4,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You\'re all caught up!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add a new task',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 80),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isDone = task.isCompleted;

        return Dismissible(
          key: Key(task.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
          ),
          onDismissed: (_) => _deleteTask(task.id),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isDone ? 0.6 : 1.0,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: isDone ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDone ? Colors.transparent : theme.colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _navigateToAddScreen(task), // Open in Edit Mode
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _toggleTaskComplete(task.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(top: 2, right: 16),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline,
                              width: 2,
                            ),
                            color: isDone ? theme.colorScheme.primary : Colors.transparent,
                          ),
                          child: isDone
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: isDone ? FontWeight.normal : FontWeight.bold,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (task.description != null && task.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                task.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Category Chip
                                if (task.category != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.category!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                // Priority Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(task.priority).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _getPriorityColor(task.priority).withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    _getPriorityText(task.priority),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getPriorityColor(task.priority),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Due Date
                                if (task.dueDate != null) ...[
                                  Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.onSurfaceVariant),
                                  Text(
                                    DateFormat('MMM d').format(task.dueDate!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
