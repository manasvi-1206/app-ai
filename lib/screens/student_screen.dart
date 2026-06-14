import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../services/notification_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/profile_initials_button.dart';
import '../widgets/task_conflict_resolver.dart';
import 'assistant_input_screen.dart';
import 'calendar_screen.dart';

class StudentScreen extends StatefulWidget {
  final String displayName;

  const StudentScreen({super.key, required this.displayName});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final List<TaskEntry> _tasks = [
    TaskEntry(
      id: 1,
      title: "AI lecture",
      dateTime: DateTime.now().add(const Duration(hours: 1)),
      source: "text",
      reminderSet: true,
    ),
  ];

  int _nextId = 100;
  int _selectedIndex = 0;
  int _completedGoals = 0;

  Future<List<TaskEntry>> _addTasks(List<TaskEntry> tasks) async {
    final result = await TaskConflictResolver.resolve(
      context: context,
      existingTasks: _tasks,
      incomingTasks: tasks,
      accentColor: const Color(0xFFE57399),
    );

    for (final task in result.updatedTasks) {
      await NotificationService.cancelForTask(task);
      await NotificationService.scheduleForTask(
        task,
        reminderBefore: task.reminderBefore ?? const Duration(days: 1),
      );
    }

    final updatedTasks = <TaskEntry>[];

    for (final task in result.addedTasks) {
      await NotificationService.scheduleForTask(
        task,
        reminderBefore: task.reminderBefore ?? const Duration(days: 1),
      );
      updatedTasks.add(task.copyWith(reminderSet: task.dateTime != null));
    }

    setState(() {
      for (final task in result.updatedTasks) {
        final index = _tasks.indexWhere((entry) => entry.id == task.id);
        if (index != -1) {
          _tasks[index] = task.copyWith(reminderSet: task.dateTime != null);
        }
      }
      _tasks.insertAll(0, updatedTasks);
      _nextId += tasks.length;
    });

    return updatedTasks;
  }

  Future<void> _deleteTask(TaskEntry task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete task"),
          content: const Text("Are you sure you want to delete this schedule?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await NotificationService.cancelForTask(task);

    setState(() {
      _tasks.removeWhere((entry) => entry.id == task.id);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Schedule deleted")));
  }

  Future<void> _completeTask(TaskEntry task) async {
    await NotificationService.cancelForTask(task);

    setState(() {
      _tasks.removeWhere((entry) => entry.id == task.id);
      _completedGoals += 1;
    });
  }

  Future<void> _openAssistantTools() async {
    final tasks = await Navigator.push<List<TaskEntry>>(
      context,
      MaterialPageRoute(
        builder: (_) => AssistantInputScreen(
          title: "Add to Student Planner",
          nextId: _nextId,
          historyKey: "student",
          enableStudentAi: true,
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
    final studyPlanTasks =
        _tasks.where((task) => task.source == "study_plan").toList()
          ..sort((a, b) {
            final aDate = a.dateTime ?? DateTime(9999);
            final bDate = b.dateTime ?? DateTime(9999);
            return aDate.compareTo(bDate);
          });
    final todayTasks =
        _tasks
            .where(
              (task) => task.source != "study_plan" && _isToday(task.dateTime),
            )
            .toList()
          ..sort(_compareTaskDate);
    final upcomingTasks =
        _tasks
            .where(
              (task) =>
                  task.source != "study_plan" &&
                  task.dateTime != null &&
                  !_isToday(task.dateTime) &&
                  task.dateTime!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort(_compareTaskDate);
    final unscheduledTasks = _tasks
        .where((task) => task.source != "study_plan" && task.dateTime == null)
        .toList();

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
        actions: _selectedIndex == 0
            ? [
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
                      color: const Color(0xFFE57399),
                    ),
                  ],
                ),
              ),
              _StudentHubCard(
                tasksCount: _tasks.length,
                notesCount: studyPlanTasks.length,
                completedGoals: _completedGoals,
              ),
              const _StudyFocusBanner(),
              if (studyPlanTasks.isNotEmpty) ...[
                const _SectionTitle("Notes"),
                _StudyPlanNotesSection(
                  tasks: studyPlanTasks,
                  onDelete: _deleteTask,
                  onComplete: _completeTask,
                ),
              ],
              const _SectionTitle("Today's Study Tasks"),
              if (todayTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    "No study tasks due today.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                )
              else
                ...todayTasks.map(
                  (task) => _StudentTaskCard(
                    task: task,
                    onDelete: _deleteTask,
                    onComplete: _completeTask,
                  ),
                ),
              if (upcomingTasks.isNotEmpty) ...[
                const _SectionTitle("Upcoming"),
                ...upcomingTasks
                    .take(5)
                    .map(
                      (task) => _StudentTaskCard(
                        task: task,
                        onDelete: _deleteTask,
                        onComplete: _completeTask,
                      ),
                    ),
              ],
              if (unscheduledTasks.isNotEmpty) ...[
                const _SectionTitle("Unscheduled"),
                ...unscheduledTasks.map(
                  (task) => _StudentTaskCard(
                    task: task,
                    onDelete: _deleteTask,
                    onComplete: _completeTask,
                  ),
                ),
              ],
            ],
          ),
          CalendarScreen(
            tasks: _tasks,
            accentColor: const Color(0xFFE57399),
            title: "Student\nSchedule",
            onDelete: _deleteTask,
            onComplete: _completeTask,
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        accentColor: const Color(0xFFE57399),
        onSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  static bool _isToday(DateTime? dateTime) {
    if (dateTime == null) {
      return false;
    }
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  static int _compareTaskDate(TaskEntry a, TaskEntry b) {
    final aDate = a.dateTime ?? DateTime(9999);
    final bDate = b.dateTime ?? DateTime(9999);
    return aDate.compareTo(bDate);
  }
}

class _StudentHubCard extends StatelessWidget {
  final int tasksCount;
  final int notesCount;
  final int completedGoals;

  const _StudentHubCard({
    required this.tasksCount,
    required this.notesCount,
    required this.completedGoals,
  });

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
              Expanded(
                child: _StudentStatCard(
                  icon: Icons.star_border,
                  iconColor: Colors.orange,
                  title: "Goals",
                  value: "$completedGoals",
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
              Expanded(
                child: _StudentStatCard(
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.pinkAccent,
                  title: "Notes",
                  value: "$notesCount",
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
  final Future<void> Function(TaskEntry) onDelete;
  final Future<void> Function(TaskEntry) onComplete;

  const _StudentTaskCard({
    required this.task,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = task.source == "image";
    final isVoice = task.source == "voice";
    final isStudyPlan = task.source == "study_plan";

    return Dismissible(
      key: ValueKey("student-task-${task.id}"),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete(task);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
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
            Checkbox(
              value: false,
              activeColor: const Color(0xFFE57399),
              onChanged: (_) => onComplete(task),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isImage
                    ? const Color(0xFFFCE4EC)
                    : const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isStudyPlan
                    ? Icons.notes_outlined
                    : isImage
                    ? Icons.image_outlined
                    : isVoice
                    ? Icons.mic_none_rounded
                    : Icons.description_outlined,
                color: isStudyPlan
                    ? Colors.deepPurple
                    : isImage
                    ? Colors.pink
                    : Colors.indigo,
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
          ],
        ),
      ),
    );
  }
}

class _StudyPlanNotesSection extends StatelessWidget {
  final List<TaskEntry> tasks;
  final Future<void> Function(TaskEntry) onDelete;
  final Future<void> Function(TaskEntry) onComplete;

  const _StudyPlanNotesSection({
    required this.tasks,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tasks
            .map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey("student-note-${task.id}"),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await onDelete(task);
                    return false;
                  },
                  background: Container(
                    padding: const EdgeInsets.only(right: 16),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_outlined,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              task.dateLabel,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: false,
                        activeColor: const Color(0xFFE57399),
                        onChanged: (_) => onComplete(task),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
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
