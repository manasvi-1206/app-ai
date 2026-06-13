import 'package:flutter/material.dart';

import '../models/task_entry.dart';

class TaskCard extends StatelessWidget {
  final TaskEntry task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2F7DFF).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_sourceIcon(), color: const Color(0xFF76A7FF)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.dateLabel,
                  style: const TextStyle(
                    color: Color(0xFFA5A5A5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (task.reminderSet)
            const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF7DDC95),
              size: 20,
            ),
        ],
      ),
    );
  }

  IconData _sourceIcon() {
    if (task.source == "image") {
      return Icons.image_outlined;
    }
    if (task.source == "voice") {
      return Icons.mic_none_rounded;
    }
    return Icons.keyboard_alt_outlined;
  }
}
