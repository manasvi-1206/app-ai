import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import 'home_screen.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continueToModes() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(displayName: _nameController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF1E1E23),
                  child: Icon(Icons.person_outline, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 22),
                const Text(
                  "What should\nI call you?",
                  style: TextStyle(
                    color: Color(0xFF151515),
                    fontSize: 42,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your name appears on Student and Professional dashboards.",
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Color(0xFF151515)),
                        decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: const TextStyle(color: Color(0xFF777777)),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF777777),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF7F2F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E1E23),
                              width: 1.4,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Enter what I should call you";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _continueToModes(),
                      ),
                      const SizedBox(height: 22),
                      CustomButton(text: "Continue", onPressed: _continueToModes),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _NamePreviewCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NamePreviewCard extends StatelessWidget {
  const _NamePreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFE57399),
            child: Text(
              "U",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "You can choose Student or Professional mode after this.",
              style: TextStyle(
                color: Color(0xFF777777),
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
