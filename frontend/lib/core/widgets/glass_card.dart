import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final BorderRadius radius;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = const BorderRadius.all(Radius.circular(24))});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(46),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withAlpha(71)),
          ),
          child: child,
        ),
      ),
    );
  }
}