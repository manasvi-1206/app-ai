import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import 'home_screen.dart';

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
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text(
                  "Registration",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignIn
                      ? "Welcome back. Sign in to continue."
                      : "Create your assistant account to continue.",
                  style: const TextStyle(
                    color: Color(0xFFA5A5A5),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 24),
                CustomButton(
                  text: _isSignIn ? "Sign in" : "Create account",
                  onPressed: _continueToModes,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _isSignIn = !_isSignIn);
                    },
                    child: Text(
                      _isSignIn
                          ? "New here? Create an account"
                          : "Already have an account? Sign in",
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
