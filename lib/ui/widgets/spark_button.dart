import 'package:flutter/material.dart';

class SparkButton extends StatelessWidget {
  const SparkButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 56,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        splashFactory: InkSparkle.splashFactory,
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            image: const DecorationImage(
              image: AssetImage('assets/images/button_sparks.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}