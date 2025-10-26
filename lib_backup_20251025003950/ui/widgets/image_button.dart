import 'package:flutter/material.dart';

class ImageButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final double minWidth;
  final double minHeight;
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.minWidth = 220,
    this.minHeight = 54,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: onPressed,
            child: Ink(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/ui/cta_button.png'),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              padding: padding,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: (textStyle ??
                          theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: const Color(0xFFFF8C23),
                          ))!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}