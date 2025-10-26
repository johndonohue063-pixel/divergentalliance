import 'package:flutter/material.dart';

/// Image-skinned button that does NOT distort your PNG.
/// - Preserves aspect ratio (fitWidth)
/// - Rounded clipping
/// - Large hit target and ripple
/// - High-contrast label with subtle shadow
class ImageButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double height;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const ImageButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 64,                               // consistent pill height
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final ts = (textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              shadows: const [
                Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(0, 1)),
              ],
            ))!;

    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 240, minHeight: 56),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: onPressed,
            child: Ink(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Your PNG scaled to the available width, keeping its aspect ratio.
                    // No stretching, no distortion.
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                        child: SizedBox(
                          height: height,
                          child: Image.asset(
                            'assets/ui/cta_button.png',
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    ),
                    // Label on top
                    Padding(
                      padding: padding,
                      child: Text(label, style: ts, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}