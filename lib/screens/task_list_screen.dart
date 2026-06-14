import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../services/notification_service.dart';
import '../widgets/task_card.dart';
import 'assistant_input_screen.dart';

class TaskListScreen extends StatefulWidget {
  final String title;
  final String emptyMessage;
  final List<TaskEntry> starterTasks;

  const TaskListScreen({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.starterTasks,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final List<TaskEntry> _tasks = List.from(widget.starterTasks);
  int _nextId = 100;

  Future<void> _addTasks(List<TaskEntry> tasks) async {
    final updatedTasks = <TaskEntry>[];

    for (final task in tasks) {
      await NotificationService.scheduleForTask(task);
      updatedTasks.add(task.copyWith(reminderSet: task.dateTime != null));
    }

    setState(() {
      _tasks.insertAll(0, updatedTasks);
      _nextId += tasks.length;
    });
  }

  Future<void> _openAssistantTools() async {
    final tasks = await Navigator.push<List<TaskEntry>>(
      context,
      MaterialPageRoute(
        builder: (_) => AssistantInputScreen(
          title: "Add to ${widget.title}",
          nextId: _nextId,
          historyKey: widget.title.toLowerCase().replaceAll(" ", "_"),
        ),
      ),
    );

    if (tasks != null && tasks.isNotEmpty) {
      await _addTasks(tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: "Add task",
            onPressed: _openAssistantTools,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        widget.emptyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFA5A5A5),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(task: _tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
