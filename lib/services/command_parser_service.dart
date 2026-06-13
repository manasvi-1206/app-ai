import '../models/task_entry.dart';

class CommandParserService {
  static final RegExp _timePattern = RegExp(
    r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
    caseSensitive: false,
  );

  static final Map<String, int> _weekdays = {
    "monday": DateTime.monday,
    "tuesday": DateTime.tuesday,
    "wednesday": DateTime.wednesday,
    "thursday": DateTime.thursday,
    "friday": DateTime.friday,
    "saturday": DateTime.saturday,
    "sunday": DateTime.sunday,
  };

  static TaskEntry parse({
    required int id,
    required String input,
    required String source,
  }) {
    final text = input.trim();
    final dateTime = _extractDateTime(text);
    final title = _extractTitle(text);

    return TaskEntry(
      id: id,
      title: title.isEmpty ? text : title,
      dateTime: dateTime,
      source: source,
    );
  }

  static List<TaskEntry> parseMany({
    required int startId,
    required String input,
    required String source,
  }) {
    final lines = input
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length > 3)
        .toList();

    return List.generate(lines.length, (index) {
      return parse(id: startId + index, input: lines[index], source: source);
    });
  }

  static DateTime? _extractDateTime(String text) {
    final lower = text.toLowerCase();
    final now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);

    if (lower.contains("tomorrow")) {
      date = date.add(const Duration(days: 1));
    } else {
      for (final entry in _weekdays.entries) {
        if (lower.contains(entry.key)) {
          date = _nextWeekday(date, entry.value);
          break;
        }
      }
    }

    final timeMatch = _timePattern.firstMatch(text);
    if (timeMatch == null) {
      return null;
    }

    var hour = int.parse(timeMatch.group(1)!);
    final minute = int.tryParse(timeMatch.group(2) ?? "0") ?? 0;
    final period = timeMatch.group(3)!.toLowerCase();

    if (period == "pm" && hour != 12) {
      hour += 12;
    }
    if (period == "am" && hour == 12) {
      hour = 0;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static DateTime _nextWeekday(DateTime from, int weekday) {
    var daysToAdd = weekday - from.weekday;
    if (daysToAdd < 0) {
      daysToAdd += 7;
    }
    return from.add(Duration(days: daysToAdd));
  }

  static String _extractTitle(String text) {
    var title = text;

    title = title.replaceAll(_timePattern, "");
    title = title.replaceAll(
      RegExp(
        r'\b(add|create|schedule|remind me to|reminder|today|tomorrow|at|on)\b',
        caseSensitive: false,
      ),
      "",
    );

    for (final day in _weekdays.keys) {
      title = title.replaceAll(RegExp(day, caseSensitive: false), "");
    }

    return title.replaceAll(RegExp(r'\s+'), " ").trim();
  }
}
