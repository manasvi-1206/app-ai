import '../models/task_entry.dart';
import 'command_parser_service.dart';

class AiPlannerService {
  static final RegExp _dateHintPattern = RegExp(
    r'\b(\d{1,2}[/-]\d{1,2}|'
    r'\d{1,2}\s+(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)|'
    r'(jan|january|feb|february|mar|march|apr|april|may|jun|june|jul|july|aug|august|sep|sept|september|oct|october|nov|november|dec|december)\s+\d{1,2}|'
    r'monday|tuesday|wednesday|thursday|friday|saturday|sunday|tomorrow|today)\b',
    caseSensitive: false,
  );

  static List<TaskEntry> analyzeExamTimetable({
    required int startId,
    required String text,
  }) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length > 2)
        .toList();

    final parsedTasks = CommandParserService.parseMany(
      startId: startId,
      input: text,
      source: "image",
    ).where((task) => task.dateTime != null).toList();

    if (parsedTasks.isNotEmpty) {
      return _improveWeakTitles(parsedTasks, lines);
    }

    final tasks = <TaskEntry>[];
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_dateHintPattern.hasMatch(line)) {
        continue;
      }

      final task = CommandParserService.parse(
        id: startId + tasks.length,
        input: "$line 9:00 AM",
        source: "image",
      );

      if (task.dateTime != null) {
        var title = _cleanExamTitle(task.title);
        if (_isWeakTitle(title)) {
          title = _titleFromNearbyLine(lines, index);
        }
        tasks.add(task.copyWith(title: title));
      }
    }

    return tasks;
  }

  static List<TaskEntry> createStudyPlan({
    required int startId,
    required String notes,
    required int days,
  }) {
    final topics = _extractStudyTopics(notes);
    if (topics.isEmpty) {
      return const [];
    }

    final today = DateTime.now();
    final planDays = days.clamp(1, 30);

    return List.generate(planDays, (index) {
      final topic = topics[index % topics.length];
      final date = DateTime(
        today.year,
        today.month,
        today.day + index + 1,
        18,
      );

      final action = switch (index) {
        0 => "Read and highlight",
        1 => "Make short notes for",
        2 => "Practice questions from",
        3 => "Revise weak points in",
        _ => "Final revision and self-test for",
      };

      return TaskEntry(
        id: startId + index,
        title: "$action $topic",
        dateTime: date,
        source: "study_plan",
      );
    });
  }

  static List<String> _extractStudyTopics(String notes) {
    final lines = notes
        .split(RegExp(r'[\n.;]'))
        .map((line) => line.trim())
        .where((line) => line.length > 5)
        .toList();

    if (lines.isEmpty) {
      return const [];
    }

    final topics = <String>[];
    for (final line in lines) {
      var topic = line.replaceAll(RegExp(r'^\d+[\).:-]?\s*'), "");
      topic = topic.replaceAll(
        RegExp(
          r'\b(these are my notes|notes|important|definition|chapter|topic)\b',
          caseSensitive: false,
        ),
        "",
      );
      topic = topic.replaceAll(RegExp(r'\s+'), " ").trim();

      if (topic.length > 48) {
        topic = topic.substring(0, 48).trim();
      }

      if (topic.length > 4 && !topics.contains(topic)) {
        topics.add(topic);
      }

      if (topics.length == 5) {
        break;
      }
    }

    return topics;
  }

  static String _cleanExamTitle(String title) {
    final cleaned = title
        .replaceAll(
          RegExp(
            r'\b(exam timetable|timetable|exam date|date|time)\b',
            caseSensitive: false,
          ),
          "",
        )
        .replaceAll(_dateHintPattern, "")
        .replaceAll(RegExp(r'\b\d{1,2}(:\d{2})?\s*(am|pm)?\b', caseSensitive: false), "")
        .replaceAll(RegExp(r'\s+'), " ")
        .trim();

    if (cleaned.toLowerCase().contains("exam")) {
      return cleaned;
    }
    return "$cleaned Exam".trim();
  }

  static List<TaskEntry> _improveWeakTitles(
    List<TaskEntry> tasks,
    List<String> lines,
  ) {
    var lineIndex = 0;
    return tasks.map((task) {
      final cleanedTitle = _cleanExamTitle(task.title);
      if (!_isWeakTitle(cleanedTitle)) {
        return task.copyWith(title: cleanedTitle);
      }

      final title = _titleFromNearbyLine(lines, lineIndex);
      lineIndex += 1;
      return task.copyWith(title: title);
    }).toList();
  }

  static String _titleFromNearbyLine(List<String> lines, int startIndex) {
    for (var offset = 0; offset < lines.length; offset++) {
      final forwardIndex = startIndex + offset;
      if (forwardIndex < lines.length) {
        final title = _candidateTitle(lines[forwardIndex]);
        if (title != null) {
          return title;
        }
      }

      final backwardIndex = startIndex - offset;
      if (backwardIndex >= 0) {
        final title = _candidateTitle(lines[backwardIndex]);
        if (title != null) {
          return title;
        }
      }
    }

    return "Exam";
  }

  static String? _candidateTitle(String line) {
    final title = _cleanExamTitle(line);
    if (_isWeakTitle(title)) {
      return null;
    }
    return title;
  }

  static bool _isWeakTitle(String title) {
    final normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'\b(exam|test|meeting|reminder)\b'), "")
        .replaceAll(RegExp(r'[^a-z]'), "")
        .trim();
    return normalized.length < 3;
  }
}
