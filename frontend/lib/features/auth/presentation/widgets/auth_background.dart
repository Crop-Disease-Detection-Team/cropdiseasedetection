import 'dart:ui';
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.asset(
          'assets/images/auth/auth_background.png',
          fit: BoxFit.cover,
        ),
        
        // Dark Gradient Overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(153),
                Colors.black.withAlpha(77),
                Colors.black.withAlpha(204),
              ],
            ),
          ),
        ),

        // Optional Subtle Blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(color: Colors.transparent),
        ),

        // Content
        child,
      ],
    );
  }
}
