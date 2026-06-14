import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import 'name_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _continueToModes() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const NameScreen()),
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
                const _AuthHeader(
                  icon: Icons.auto_awesome,
                  title: "Start planning",
                  subtitle: "Create your assistant space for study, work, and reminders.",
                ),
                const SizedBox(height: 28),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSignIn ? "Welcome back" : "Create account",
                        style: const TextStyle(
                          color: Color(0xFF151515),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignIn
                            ? "Sign in and continue to your planner."
                            : "Use any email to continue for now.",
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Color(0xFF151515)),
                        decoration: _inputDecoration(
                          label: "Email",
                          icon: Icons.email_outlined,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? "";
                          if (email.isEmpty) {
                            return "Enter your email";
                          }
                          if (!email.contains("@")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Color(0xFF151515)),
                        decoration: _inputDecoration(
                          label: "Password",
                          icon: Icons.lock_outline,
                        ),
                        validator: (value) {
                          final password = value ?? "";
                          if (password.isEmpty) {
                            return "Enter your password";
                          }
                          if (!_isSignIn && password.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _continueToModes(),
                      ),
                      const SizedBox(height: 22),
                      CustomButton(
                        text: _isSignIn ? "Sign in" : "Create account",
                        onPressed: _continueToModes,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isSignIn = !_isSignIn);
                          },
                          child: Text(
                            _isSignIn
                                ? "New here? Create an account"
                                : "Already have an account? Sign in",
                            style: const TextStyle(
                              color: Color(0xFF1E1E23),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF777777)),
      prefixIcon: Icon(icon, color: const Color(0xFF777777)),
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
        borderSide: const BorderSide(color: Color(0xFF1E1E23), width: 1.4),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AuthHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1E1E23),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF151515),
            fontSize: 42,
            height: 1.02,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF777777),
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
