import 'package:flutter/material.dart';
import 'package:divergent_alliance/ui/widgets/spark_button.dart';

class DAButton extends StatelessWidget {
  const DAButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.height = 56,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget content = child ?? Text(label ?? '', style: const TextStyle(fontWeight: FontWeight.w700));
    return SparkButton(onPressed: onPressed, child: content, height: height, width: width, borderRadius: borderRadius);
  }
}