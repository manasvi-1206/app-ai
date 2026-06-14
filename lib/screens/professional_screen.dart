import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../services/notification_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/profile_initials_button.dart';
import 'assistant_input_screen.dart';
import 'calendar_screen.dart';

class ProfessionalScreen extends StatefulWidget {
  final String displayName;

  const ProfessionalScreen({super.key, required this.displayName});

  @override
  State<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends State<ProfessionalScreen> {
  final List<TaskEntry> _tasks = [
    TaskEntry(
      id: 50,
      title: "Project sync meeting",
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      source: "text",
      reminderSet: true,
    ),
  ];

  int _nextId = 200;
  int _selectedIndex = 0;

  Future<void> _addTasks(List<TaskEntry> tasks) async {
    final updatedTasks = <TaskEntry>[];

    for (final task in tasks) {
      await NotificationService.scheduleForTask(
        task,
        reminderBefore: const Duration(hours: 1),
      );
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
          title: "Add to Professional Planner",
          nextId: _nextId,
          historyKey: "professional",
          onTasksCreated: _addTasks,
        ),
      ),
    );

    if (tasks == null || tasks.isEmpty) {
      return;
    }

    await _addTasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Professional Planner",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  tooltip: "Add task",
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF2F7DFF),
                    size: 32,
                  ),
                  onPressed: _openAssistantTools,
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Welcome, ${widget.displayName}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    ProfileInitialsButton(
                      displayName: widget.displayName,
                      color: const Color(0xFF2F7DFF),
                    ),
                  ],
                ),
              ),
              _ProfessionalHubCard(tasksCount: _tasks.length),
              const _WorkFocusBanner(),
              const _SectionTitle("Today's Work Tasks"),
              if (_tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "Add your first work task using the plus button.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                )
              else
                ..._tasks.map((task) => _ProfessionalTaskCard(task: task)),
            ],
          ),
          CalendarScreen(
            tasks: _tasks,
            accentColor: const Color(0xFF2F7DFF),
            title: "Professional\nSchedule",
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        accentColor: const Color(0xFF2F7DFF),
        onSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

class _ProfessionalHubCard extends StatelessWidget {
  final int tasksCount;

  const _ProfessionalHubCard({required this.tasksCount});

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
          colors: [Color(0xFFEAF2FF), Color(0xFFDCEBFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.work_outline, color: Color(0xFF2F7DFF), size: 28),
              SizedBox(width: 8),
              Text(
                "Work Hub",
                style: TextStyle(
                  color: Color(0xFF1558C0),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Stay sharp, organized, and on schedule.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ProfessionalStatCard(
                  icon: Icons.task_alt,
                  iconColor: const Color(0xFF2F7DFF),
                  title: "Tasks",
                  value: "$tasksCount",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _ProfessionalStatCard(
                  icon: Icons.groups_outlined,
                  iconColor: Colors.teal,
                  title: "Meetings",
                  value: "1",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _ProfessionalStatCard(
                  icon: Icons.flag_outlined,
                  iconColor: Colors.deepOrange,
                  title: "Projects",
                  value: "2",
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _ProfessionalStatCard(
                  icon: Icons.description_outlined,
                  iconColor: Colors.indigo,
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

class _WorkFocusBanner extends StatelessWidget {
  const _WorkFocusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.insights_outlined, color: Colors.white, size: 45),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Capture meetings, reminders, and project actions in one place.",
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

class _ProfessionalTaskCard extends StatelessWidget {
  final TaskEntry task;

  const _ProfessionalTaskCard({required this.task});

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
                  ? const Color(0xFFE0F2F1)
                  : const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isImage
                  ? Icons.image_outlined
                  : isVoice
                  ? Icons.mic_none_rounded
                  : Icons.business_center_outlined,
              color: isImage ? Colors.teal : const Color(0xFF2F7DFF),
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
            const Icon(Icons.notifications_none, color: Color(0xFF2F7DFF)),
        ],
      ),
    );
  }
}

class _ProfessionalStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _ProfessionalStatCard({
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
