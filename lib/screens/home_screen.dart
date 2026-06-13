import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'student_screen.dart';
import 'professional_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Personal Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              "Choose your workspace",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add tasks by typing, speaking, or uploading images inside each mode.",
              style: TextStyle(color: Color(0xFFA5A5A5), fontSize: 15),
            ),
            const Spacer(),
            CustomButton(
              text: "Student Mode",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StudentScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Professional Mode",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfessionalScreen()),
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
