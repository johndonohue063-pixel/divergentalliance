import 'package:flutter/material.dart';

class DABubbleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed; // allow disabled state
  final bool filled;
  final Color brand;

  const DABubbleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? brand : Colors.black;
    final fg = filled ? Colors.black : brand;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52, minWidth: 120),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: fg),
        label: Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 6,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: const StadiumBorder(),
          side: BorderSide(color: brand, width: 2),
          minimumSize: const Size(0, 52),           // flexible width
          maximumSize: const Size(600, double.infinity),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
