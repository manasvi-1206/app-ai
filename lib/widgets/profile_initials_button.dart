import 'package:flutter/material.dart';

class ProfileInitialsButton extends StatelessWidget {
  final String displayName;
  final Color color;

  const ProfileInitialsButton({
    super.key,
    required this.displayName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        _initials(displayName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return "U";
    }
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return "${parts.first.characters.first}${parts.last.characters.first}"
        .toUpperCase();
  }
}
