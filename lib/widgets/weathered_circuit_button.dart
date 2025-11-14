import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



/// Wood + metal sprite button. Renders your PNG end-to-end (no cropping),
/// accepts the same named args your screen already passes.
class WeatheredCircuitButton extends StatelessWidget {
  const WeatheredCircuitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width = 240,
    this.height = 64,
    this.borderThickness = 0,                                   // kept for API compatibility
    this.woodTextureAsset = "assets/images/weathered_circuit_button_transparent.png",
    this.textColor = Colors.white,
    this.spriteAspect = 3.8,                                    // sprite width / height; tweak if needed
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double width;
  final double height;

  // accepted but not required by this implementation (kept so callers compile unchanged)
  final double borderThickness;
  final String woodTextureAsset;
  final Color textColor;

  // controls how wide the sprite renders relative to its height
  final double spriteAspect;

  @override
  Widget build(BuildContext context) {
    // Image sprite sized by aspect, then scaled to fit without clipping.
    final image = Center(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(
          width: spriteAspect * height,
          height: height,
          child: Image.asset(
            woodTextureAsset,
            fit: BoxFit.fill,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF2B211A)),
          ),
        ),
      ),
    );

    final labelRow = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: height * 0.42, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.goldman(
                  fontSize: height * 0.30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.65),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),

              ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Stack(fit: StackFit.expand, children: [image, labelRow]),
        ),
      ),
    );
  }
}
