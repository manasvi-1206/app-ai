import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../services/notification_service.dart';
import 'assistant_input_screen.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final List<TaskEntry> _tasks = [
    TaskEntry(
      id: 1,
      title: "AI lecture",
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      source: "text",
      reminderSet: true,
    ),
    const TaskEntry(
      id: 2,
      title: "Upload timetable screenshot",
      source: "image",
    ),
  ];

  int _nextId = 100;

  Future<void> _openAssistantTools() async {
    final tasks = await Navigator.push<List<TaskEntry>>(
      context,
      MaterialPageRoute(
        builder: (_) => AssistantInputScreen(
          title: "Add to Student Planner",
          nextId: _nextId,
        ),
      ),
    );

    if (tasks == null || tasks.isEmpty) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Student Planner",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Add task",
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFFE57399),
              size: 32,
            ),
            onPressed: _openAssistantTools,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _StudentHubCard(tasksCount: _tasks.length),
          const _StudyFocusBanner(),
          const _SectionTitle("Today's Study Tasks"),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                "Add your first study task using the plus button.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
          else
            ..._tasks.map((task) => _StudentTaskCard(task: task)),
        ],
      ),
    );
  }
}

class _StudentHubCard extends StatelessWidget {
  final int tasksCount;

  const _StudentHubCard({required this.tasksCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F3), Color(0xFFFFE5EC)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, color: Color(0xFFE57399), size: 28),
              SizedBox(width: 8),
              Text(
                "Student Hub",
                style: TextStyle(
                  color: Color(0xFFD81B60),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Keep learning, keep growing.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StudentStatCard(
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.redAccent,
                  title: "Tasks",
                  value: "$tasksCount",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StudentStatCard(
                  icon: Icons.star_border,
                  iconColor: Colors.orange,
                  title: "Goals",
                  value: "1",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StudentStatCard(
                  icon: Icons.calendar_today_outlined,
                  iconColor: Colors.purple,
                  title: "Tests",
                  value: "0",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StudentStatCard(
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.pinkAccent,
                  title: "Notes",
                  value: "0",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudyFocusBanner extends StatelessWidget {
  const _StudyFocusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFB39DDB), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.track_changes, color: Colors.white, size: 45),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Plan your next steps to achieve academic goals.",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _StudentTaskCard extends StatelessWidget {
  final TaskEntry task;

  const _StudentTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isImage = task.source == "image";
    final isVoice = task.source == "voice";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isImage
                  ? const Color(0xFFFCE4EC)
                  : const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isImage
                  ? Icons.image_outlined
                  : isVoice
                  ? Icons.mic_none_rounded
                  : Icons.description_outlined,
              color: isImage ? Colors.pink : Colors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.dateLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (task.reminderSet)
            const Icon(Icons.notifications_none, color: Colors.indigoAccent),
        ],
      ),
    );
  }
}

class _StudentStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _StudentStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
