import 'package:flutter/material.dart';

import 'professional_screen.dart';
import 'student_screen.dart';

class HomeScreen extends StatelessWidget {
  final String displayName;

  const HomeScreen({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F4),
        foregroundColor: const Color(0xFF151515),
        title: const Text("AI Personal Assistant"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $displayName",
              style: const TextStyle(
                color: Color(0xFF151515),
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose your workspace to continue.",
              style: TextStyle(color: Color(0xFF777777), fontSize: 15),
            ),
            const SizedBox(height: 28),
            _WorkspaceCard(
              icon: Icons.school_outlined,
              title: "Student Mode",
              subtitle: "Classes, tests, study reminders, and timetable photos.",
              color: const Color(0xFFE57399),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentScreen(displayName: displayName),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _WorkspaceCard(
              icon: Icons.work_outline,
              title: "Professional Mode",
              subtitle: "Meetings, project actions, and work reminders.",
              color: const Color(0xFF2F7DFF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfessionalScreen(displayName: displayName),
                  ),
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WorkspaceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF151515),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF777777),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF777777)),
          ],
        ),
      ),
    );
  }
}
