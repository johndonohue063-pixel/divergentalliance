import "package:flutter/material.dart";

class WcFilters extends StatelessWidget {
  final bool gustSelected;
  final bool sustainedSelected;
  final int minSeverity; // 1..5
  final double windowHours; // 0..72

  final ValueChanged<bool> onGustChanged;
  final ValueChanged<bool> onSustainedChanged;
  final ValueChanged<int> onMinSeverityChanged;
  final ValueChanged<double> onWindowChanged;

  const WcFilters({
    super.key,
    required this.gustSelected,
    required this.sustainedSelected,
    required this.minSeverity,
    required this.windowHours,
    required this.onGustChanged,
    required this.onSustainedChanged,
    required this.onMinSeverityChanged,
    required this.onWindowChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(color: const Color(0xFFA2A7B5));
    final chipTextStyle = theme.textTheme.bodyMedium;

    Widget chip(String text, bool selected, VoidCallback onTap){
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF17181C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFF4F8CFF) : const Color(0xFF2A2D35), width: selected ? 2 : 1),
          ),
          child: Text(text, style: chipTextStyle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wind Metric
        Text("Wind Metric", style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip("✓ Gust", gustSelected, () => onGustChanged(!gustSelected)),
            chip("✓ Sustained", sustainedSelected, () => onSustainedChanged(!sustainedSelected)),
          ],
        ),
        const SizedBox(height: 16),

        // Minimum Threat Level
        Text("Minimum Threat Level", style: labelStyle),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(5, (i){
            final n = i + 1;
            return chip("Min Sev $n", minSeverity == n, () => onMinSeverityChanged(n));
          }),
        ),
        const SizedBox(height: 16),

        // Window hours slider
        Text("Window (hours)", style: labelStyle),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: windowHours.clamp(0, 72),
                min: 0,
                max: 72,
                divisions: 72,
                label: "${windowHours.round()}",
                onChanged: onWindowChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text("${windowHours.round()}h", style: labelStyle),
          ],
        ),
      ],
    );
  }
}