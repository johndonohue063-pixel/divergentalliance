import "package:flutter/material.dart";
import "da_brand.dart";

class DAButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final double height;

  const DAButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final child = _content();
    // Try to use the asset background; if missing, fallback is used
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: DABrand.orange,
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              offset: Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
          border: Border.all(color: Colors.black, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Asset background (silently fails if not present)
            Image.asset(
              "assets/ui/da_button.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                // Fallback: subtle radial + linear blend to suggest texture
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DABrand.orange,
                        const Color(0xFFFF7A24),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                );
              },
            ),
            // Subtle overlay to keep text legible across the art
            Container(color: Colors.black.withValues(alpha: 0.08)),
            Center(child: child),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final text = Text(
      label,
      style: const TextStyle(
        color: DABrand.black,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        fontSize: 16,
      ),
    );
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: DABrand.black, size: 18),
        const SizedBox(width: 8),
        text,
      ],
    );
  }
}
