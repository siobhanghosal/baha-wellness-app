import 'package:flutter/material.dart';

class BahaSurface extends StatelessWidget {
  const BahaSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
