import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../services/ai_history_service.dart';
import '../widgets/smart_input_bar.dart';

class AssistantInputScreen extends StatefulWidget {
  final String title;
  final int nextId;
  final String historyKey;
  final Future<void> Function(List<TaskEntry>)? onTasksCreated;

  const AssistantInputScreen({
    super.key,
    required this.title,
    required this.nextId,
    required this.historyKey,
    this.onTasksCreated,
  });

  @override
  State<AssistantInputScreen> createState() => _AssistantInputScreenState();
}

class _AssistantInputScreenState extends State<AssistantInputScreen> {
  final List<TaskEntry> _createdTasks = [];

  void _finish() {
    Navigator.pop<List<TaskEntry>>(
      context,
      widget.onTasksCreated == null ? _createdTasks : const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = AiHistoryService.entriesFor(widget.historyKey).reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F4),
        foregroundColor: const Color(0xFF151515),
        elevation: 0,
        title: Text(widget.title),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _finish,
        ),
        actions: [
          if (_createdTasks.isNotEmpty)
            TextButton(
              onPressed: _finish,
              child: const Text(
                "Done",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              children: [
                const _AssistantIntroCard(),
                if (_createdTasks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Added in this session",
                    style: _sectionStyle,
                  ),
                  const SizedBox(height: 10),
                  ..._createdTasks.map((task) => _DetectedTaskCard(task: task)),
                ],
                const SizedBox(height: 16),
                Text("Chat history", style: _sectionStyle),
                const SizedBox(height: 10),
                if (history.isEmpty)
                  const _EmptyHistoryCard()
                else
                  ...history.map((entry) => _HistoryBubble(entry: entry)),
              ],
            ),
          ),
          SmartInputBar(
            nextId: widget.nextId + _createdTasks.length,
            historyKey: widget.historyKey,
            onHistoryChanged: () {
              setState(() {});
            },
            onEntriesCreated: (tasks) async {
              setState(() {
                _createdTasks.addAll(tasks);
              });
              await widget.onTasksCreated?.call(tasks);
            },
          ),
        ],
      ),
    );
  }
}

const TextStyle _sectionStyle = TextStyle(
  color: Color(0xFF151515),
  fontSize: 17,
  fontWeight: FontWeight.w800,
);

class _AssistantIntroCard extends StatelessWidget {
  const _AssistantIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFF1E1E23),
            child: Icon(Icons.auto_awesome, color: Colors.white),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "Type, speak, or upload a timetable photo. I will detect task names, dates, and times.",
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetectedTaskCard extends StatelessWidget {
  final TaskEntry task;

  const _DetectedTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2979FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Color(0xFF151515),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.dateLabel,
                  style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBubble extends StatelessWidget {
  final AiHistoryEntry entry;

  const _HistoryBubble({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E23),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.userPrompt,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.aiResponse,
              style: const TextStyle(color: Color(0xFF151515), fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "Your assistant messages will appear here.",
        style: TextStyle(color: Color(0xFF777777), fontSize: 14),
      ),
    );
  }
}
