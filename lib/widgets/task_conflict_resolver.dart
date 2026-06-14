import 'package:flutter/material.dart';

import '../models/task_entry.dart';

class TaskConflictResult {
  final List<TaskEntry> addedTasks;
  final List<TaskEntry> updatedTasks;

  const TaskConflictResult({
    required this.addedTasks,
    required this.updatedTasks,
  });
}

class TaskConflictResolver {
  static Future<TaskConflictResult> resolve({
    required BuildContext context,
    required List<TaskEntry> existingTasks,
    required List<TaskEntry> incomingTasks,
    required Color accentColor,
  }) async {
    final addedTasks = <TaskEntry>[];
    final updatedTasks = <TaskEntry>[];
    final originalIds = existingTasks.map((task) => task.id).toSet();
    final scheduledTasks = [...existingTasks];

    for (final task in incomingTasks) {
      if (task.dateTime == null) {
        addedTasks.add(task);
        scheduledTasks.add(task);
        continue;
      }

      final conflict = _findConflict(scheduledTasks, task);
      if (conflict == null) {
        addedTasks.add(task);
        scheduledTasks.add(task);
        continue;
      }

      final suggestedTime = _suggestNextSlot(
        scheduledTasks,
        task.dateTime!,
        ignoreIds: {conflict.id, task.id},
      );
      if (!context.mounted) {
        break;
      }

      final decision = await _showConflictDialog(
        context: context,
        currentTask: conflict,
        newTask: task,
        suggestedTime: suggestedTime,
        accentColor: accentColor,
      );

      if (decision == null) {
        continue;
      }

      if (decision.choice == _ConflictChoice.keepCurrent) {
        final movedTask = task.copyWith(dateTime: decision.otherTaskDateTime);
        addedTasks.add(movedTask);
        scheduledTasks.add(movedTask);
        continue;
      }

      final movedConflict = conflict.copyWith(
        dateTime: decision.otherTaskDateTime,
      );
      _replaceTask(scheduledTasks, movedConflict);

      if (originalIds.contains(conflict.id)) {
        updatedTasks.removeWhere((entry) => entry.id == movedConflict.id);
        updatedTasks.add(movedConflict);
      } else {
        _replaceTask(addedTasks, movedConflict);
      }

      addedTasks.add(task);
      scheduledTasks.add(task);
    }

    return TaskConflictResult(
      addedTasks: addedTasks,
      updatedTasks: updatedTasks,
    );
  }

  static TaskEntry? _findConflict(List<TaskEntry> tasks, TaskEntry incoming) {
    return tasks.cast<TaskEntry?>().firstWhere(
      (task) =>
          task?.dateTime != null &&
          _isSameMinute(task!.dateTime!, incoming.dateTime!),
      orElse: () => null,
    );
  }

  static DateTime _suggestNextSlot(
    List<TaskEntry> tasks,
    DateTime preferredTime, {
    Set<int> ignoreIds = const {},
  }) {
    var suggestion = preferredTime.add(const Duration(minutes: 30));

    for (var i = 0; i < 336; i++) {
      final isFree = tasks.every(
        (task) =>
            ignoreIds.contains(task.id) ||
            task.dateTime == null ||
            !_isSameMinute(task.dateTime!, suggestion),
      );

      if (isFree) {
        return suggestion;
      }

      suggestion = suggestion.add(const Duration(minutes: 30));
    }

    return preferredTime.add(const Duration(hours: 1));
  }

  static void _replaceTask(List<TaskEntry> tasks, TaskEntry updatedTask) {
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index == -1) {
      tasks.add(updatedTask);
      return;
    }
    tasks[index] = updatedTask;
  }

  static bool _isSameMinute(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day &&
        first.hour == second.hour &&
        first.minute == second.minute;
  }

  static Future<_ConflictDecision?> _showConflictDialog({
    required BuildContext context,
    required TaskEntry currentTask,
    required TaskEntry newTask,
    required DateTime suggestedTime,
    required Color accentColor,
  }) {
    var choice = _ConflictChoice.keepCurrent;
    var otherTaskDateTime = suggestedTime;

    return showDialog<_ConflictDecision>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final otherTask = choice == _ConflictChoice.keepCurrent
                ? newTask
                : currentTask;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text("Time already assigned"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "A task already exists at ${_formatDateTime(newTask.dateTime!)}.",
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "Which one should stay in this slot?",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ConflictOptionTile(
                      selected: choice == _ConflictChoice.keepCurrent,
                      accentColor: accentColor,
                      title: Text(currentTask.title),
                      subtitle: const Text("Already assigned"),
                      onTap: () => setDialogState(
                        () => choice = _ConflictChoice.keepCurrent,
                      ),
                    ),
                    _ConflictOptionTile(
                      selected: choice == _ConflictChoice.keepNew,
                      accentColor: accentColor,
                      title: Text(newTask.title),
                      subtitle: const Text("New task"),
                      onTap: () => setDialogState(
                        () => choice = _ConflictChoice.keepNew,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Choose time for ${otherTask.title}",
                            style: const TextStyle(
                              color: Color(0xFF151515),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatDateTime(otherTaskDateTime),
                            style: const TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final pickedDate = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: otherTaskDateTime,
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 1),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 730),
                                    ),
                                  );

                                  if (pickedDate == null ||
                                      !dialogContext.mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    otherTaskDateTime = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      otherTaskDateTime.hour,
                                      otherTaskDateTime.minute,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.calendar_today),
                                label: const Text("Date"),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final pickedTime = await showTimePicker(
                                    context: dialogContext,
                                    initialTime: TimeOfDay.fromDateTime(
                                      otherTaskDateTime,
                                    ),
                                  );

                                  if (pickedTime == null ||
                                      !dialogContext.mounted) {
                                    return;
                                  }

                                  setDialogState(() {
                                    otherTaskDateTime = DateTime(
                                      otherTaskDateTime.year,
                                      otherTaskDateTime.month,
                                      otherTaskDateTime.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                },
                                icon: const Icon(Icons.access_time),
                                label: const Text("Time"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    _ConflictDecision(
                      choice: choice,
                      otherTaskDateTime: otherTaskDateTime,
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}";
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }
}

class _ConflictDecision {
  final _ConflictChoice choice;
  final DateTime otherTaskDateTime;

  const _ConflictDecision({
    required this.choice,
    required this.otherTaskDateTime,
  });
}

class _ConflictOptionTile extends StatelessWidget {
  final bool selected;
  final Color accentColor;
  final Widget title;
  final Widget subtitle;
  final VoidCallback onTap;

  const _ConflictOptionTile({
    required this.selected,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? accentColor : const Color(0xFF777777),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: Color(0xFF151515),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    child: title,
                  ),
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 12,
                    ),
                    child: subtitle,
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

enum _ConflictChoice { keepCurrent, keepNew }
