class TaskEntry {
  final int id;
  final String title;
  final DateTime? dateTime;
  final String source;
  final bool reminderSet;
  final Duration? reminderBefore;

  const TaskEntry({
    required this.id,
    required this.title,
    required this.source,
    this.dateTime,
    this.reminderSet = false,
    this.reminderBefore,
  });

  String get dateLabel {
    if (dateTime == null) {
      return "No time detected";
    }

    final hour = dateTime!.hour > 12
        ? dateTime!.hour - 12
        : dateTime!.hour == 0
        ? 12
        : dateTime!.hour;
    final minute = dateTime!.minute.toString().padLeft(2, '0');
    final period = dateTime!.hour >= 12 ? "PM" : "AM";

    return "${dateTime!.day}/${dateTime!.month}/${dateTime!.year} at $hour:$minute $period";
  }

  TaskEntry copyWith({
    int? id,
    String? title,
    DateTime? dateTime,
    String? source,
    bool? reminderSet,
    Duration? reminderBefore,
  }) {
    return TaskEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      source: source ?? this.source,
      reminderSet: reminderSet ?? this.reminderSet,
      reminderBefore: reminderBefore ?? this.reminderBefore,
    );
  }
}
