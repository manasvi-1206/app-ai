import 'package:flutter/material.dart';

class BuddyLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const BuddyLogo({super.key, this.size = 56, this.showWordmark = false});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E23),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "B",
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.46,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          Positioned(
            right: size * 0.16,
            top: size * 0.14,
            child: Icon(
              Icons.auto_awesome,
              color: const Color(0xFFFFD66B),
              size: size * 0.26,
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) {
      return mark;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        const Text(
          "Buddy",
          style: TextStyle(
            color: Color(0xFF151515),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
