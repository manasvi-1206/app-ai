import 'package:flutter/material.dart';

import '../models/task_entry.dart';
import '../widgets/smart_input_bar.dart';

class AssistantInputScreen extends StatelessWidget {
  final String title;
  final int nextId;

  const AssistantInputScreen({
    super.key,
    required this.title,
    required this.nextId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: false),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Type your task, speak with the assistant, or upload an image.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA5A5A5), fontSize: 16),
                ),
              ),
            ),
          ),
          SmartInputBar(
            nextId: nextId,
            onEntriesCreated: (tasks) {
              Navigator.pop<List<TaskEntry>>(context, tasks);
            },
          ),
        ],
      ),
    );
  }
}
