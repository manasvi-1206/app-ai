import '../models/task_entry.dart';

class CommandParserService {
  static final RegExp _timePattern = RegExp(
    r'\b(\d{1,2})(?::(\d{2}))?\s*([ap])\s*([mn])\b',
    caseSensitive: false,
  );
  static final RegExp _twentyFourHourTimePattern = RegExp(
    r'\b([01]?\d|2[0-3]):([0-5]\d)\b',
  );
  static final RegExp _daysLaterPattern = RegExp(
    r'\b(?:in|after)?\s*(\d{1,3})(?:\s*(?:-|to)\s*\d{1,3})?\s*days?\s*(?:later|from now)?\b',
    caseSensitive: false,
  );
  static final RegExp _slashDatePattern = RegExp(
    r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b',
  );
  static final RegExp _dayMonthPattern = RegExp(
    r'\b(\d{1,2})\s+(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\b',
    caseSensitive: false,
  );
  static final RegExp _monthDayPattern = RegExp(
    r'\b(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s+(\d{1,2})\b',
    caseSensitive: false,
  );
  static final RegExp _reminderBeforePattern = RegExp(
    r'\b(?:notify|remind|alert)?\s*(?:me)?\s*(?:(\d{1,3})\s*)?(minute|minutes|min|mins|hour|hours|hr|hrs|day|days)\s*(?:before|earlier|prior|ahead|early)\b',
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

  static final Map<String, int> _months = {
    "jan": 1,
    "january": 1,
    "feb": 2,
    "february": 2,
    "mar": 3,
    "march": 3,
    "apr": 4,
    "april": 4,
    "may": 5,
    "jun": 6,
    "june": 6,
    "jul": 7,
    "july": 7,
    "aug": 8,
    "august": 8,
    "sep": 9,
    "sept": 9,
    "september": 9,
    "oct": 10,
    "october": 10,
    "nov": 11,
    "november": 11,
    "dec": 12,
    "december": 12,
  };

  static TaskEntry parse({
    required int id,
    required String input,
    required String source,
  }) {
    final text = input.trim();
    final dateTime = _extractDateTime(text);
    final title = _extractTitle(text);
    final reminderBefore = _extractReminderBefore(text);

    return TaskEntry(
      id: id,
      title: title.isEmpty ? text : title,
      dateTime: dateTime,
      source: source,
      reminderBefore: reminderBefore,
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

    final tasks = <TaskEntry>[];
    DateTime? activeDate;

    for (final line in lines) {
      final detectedDate = _extractDateOnly(line);
      final detectedTime = _extractTime(line);

      if (detectedDate != null) {
        activeDate = detectedDate;
      }

      if (detectedTime == null) {
        continue;
      }

      final taskDate = detectedDate ?? activeDate ?? _today();
      final dateTime = DateTime(
        taskDate.year,
        taskDate.month,
        taskDate.day,
        detectedTime.hour,
        detectedTime.minute,
      );
      final title = _extractTitle(line);
      final reminderBefore = _extractReminderBefore(line);

      tasks.add(
        TaskEntry(
          id: startId + tasks.length,
          title: title.isEmpty ? line : title,
          dateTime: dateTime,
          source: source,
          reminderBefore: reminderBefore,
        ),
      );
    }

    if (tasks.isNotEmpty) {
      return tasks;
    }

    return List.generate(lines.length, (index) {
      return parse(id: startId + index, input: lines[index], source: source);
    });
  }

  static DateTime? _extractDateTime(String text) {
    final date = _extractDateOnly(text) ?? _today();
    final time = _extractTime(text);

    if (time == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime? _extractDateOnly(String text) {
    final lower = text.toLowerCase();
    DateTime date = _today();

    final explicitDate = _slashDatePattern.firstMatch(text);
    if (explicitDate != null) {
      final day = int.parse(explicitDate.group(1)!);
      final month = int.parse(explicitDate.group(2)!);
      final yearText = explicitDate.group(3);
      var year = _resolveYear(month, day, yearText);

      return DateTime(year, month, day);
    }

    final dayMonth = _dayMonthPattern.firstMatch(text);
    if (dayMonth != null) {
      final day = int.parse(dayMonth.group(1)!);
      final month = _months[dayMonth.group(2)!.toLowerCase()]!;
      return DateTime(_resolveYear(month, day, null), month, day);
    }

    final monthDay = _monthDayPattern.firstMatch(text);
    if (monthDay != null) {
      final month = _months[monthDay.group(1)!.toLowerCase()]!;
      final day = int.parse(monthDay.group(2)!);
      return DateTime(_resolveYear(month, day, null), month, day);
    }

    final daysLater = _daysLaterPattern.firstMatch(lower);
    if (daysLater != null) {
      final days = int.parse(daysLater.group(1)!);
      return date.add(Duration(days: days));
    }

    if (lower.contains("tomorrow")) {
      return date.add(const Duration(days: 1));
    }

    if (lower.contains("today")) {
      return date;
    }

    for (final entry in _weekdays.entries) {
      if (lower.contains(entry.key)) {
        return _nextWeekday(date, entry.value);
      }
    }

    return null;
  }

  static _ParsedTime? _extractTime(String text) {
    final timeMatch = _timePattern.firstMatch(text);
    if (timeMatch != null) {
      var hour = int.parse(timeMatch.group(1)!);
      final minute = int.tryParse(timeMatch.group(2) ?? "0") ?? 0;
      final period = timeMatch.group(3)!.toLowerCase() == "p" ? "pm" : "am";

      if (period == "pm" && hour != 12) {
        hour += 12;
      }
      if (period == "am" && hour == 12) {
        hour = 0;
      }

      return _ParsedTime(hour, minute);
    }

    final twentyFourHourMatch = _twentyFourHourTimePattern.firstMatch(text);
    if (twentyFourHourMatch != null) {
      return _ParsedTime(
        int.parse(twentyFourHourMatch.group(1)!),
        int.parse(twentyFourHourMatch.group(2)!),
      );
    }

    return null;
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
    title = title.replaceAll(_twentyFourHourTimePattern, "");
    title = title.replaceAll(_slashDatePattern, "");
    title = title.replaceAll(_dayMonthPattern, "");
    title = title.replaceAll(_monthDayPattern, "");
    title = title.replaceAll(_daysLaterPattern, "");
    title = title.replaceAll(_reminderBeforePattern, "");
    title = title.replaceAll(
      RegExp(
        r'\b(add|create|schedule|remind me to|remind|notify me|notify|alert me|alert|reminder|today|tomorrow|at|on|in|after|from now)\b',
        caseSensitive: false,
      ),
      "",
    );

    for (final day in _weekdays.keys) {
      title = title.replaceAll(RegExp(day, caseSensitive: false), "");
    }

    return title
        .replaceAll(RegExp(r'\s*[-–—]\s*'), " ")
        .replaceAll(RegExp(r'\s+'), " ")
        .trim();
  }

  static Duration? _extractReminderBefore(String text) {
    final lower = text.toLowerCase();

    if (lower.contains("on time") ||
        lower.contains("at the time") ||
        lower.contains("notify me then") ||
        lower.contains("remind me then")) {
      return Duration.zero;
    }

    final match = _reminderBeforePattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    final amount = int.tryParse(match.group(1) ?? "1") ?? 1;
    final unit = match.group(2)!.toLowerCase();

    if (unit.startsWith("min")) {
      return Duration(minutes: amount);
    }
    if (unit.startsWith("h")) {
      return Duration(hours: amount);
    }
    return Duration(days: amount);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static int _resolveYear(int month, int day, String? yearText) {
    final now = DateTime.now();
    if (yearText != null) {
      var year = int.parse(yearText);
      if (year < 100) {
        year += 2000;
      }
      return year;
    }

    final date = DateTime(now.year, month, day);
    return date.isBefore(_today()) ? now.year + 1 : now.year;
  }
}

class _ParsedTime {
  final int hour;
  final int minute;

  const _ParsedTime(this.hour, this.minute);
}
