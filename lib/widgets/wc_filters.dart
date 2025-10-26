import "package:flutter/material.dart";

const Color kBg = Color(0xFF0B0B0D);     // pitch-ish black
const Color kCard = Color(0xFF111214);   // card
const Color kBorder = Color(0xFF2A2D35); // border
const Color kText = Colors.white;        // primary text
const Color kMuted = Color(0xFFA2A7B5);  // muted text
const Color kBrand = Color(0xFFFF7A00);  // Divergent orange
const Color kTrack = Color(0xFF3A3D45);  // slider inactive

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
    TextStyle labelStyle = const TextStyle(color: kText, fontSize: 13, fontWeight: FontWeight.w600);
    TextStyle chipText  = const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600);

    Widget chip(String text, bool selected, VoidCallback onTap){
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1B1F) : kCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? kBrand : kBorder, width: selected ? 2 : 1),
            boxShadow: selected ? [BoxShadow(color: kBrand.withOpacity(0.25), blurRadius: 10, spreadRadius: 0)] : const [],
          ),
          child: Text(text, style: chipText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wind Metric
        Text("Wind Metric", style: labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: [
            chip("✓ Gust", gustSelected, () => onGustChanged(!gustSelected)),
            chip("✓ Sustained", sustainedSelected, () => onSustainedChanged(!sustainedSelected)),
          ],
        ),
        const SizedBox(height: 18),

        // Minimum Threat Level
        Text("Minimum Threat Level", style: labelStyle),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: List.generate(5, (i){
            final n = i + 1;
            return chip("Min Sev $n", minSeverity == n, () => onMinSeverityChanged(n));
          }),
        ),
        const SizedBox(height: 18),

        // Window hours slider
        Text("Window (hours)", style: labelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: kBrand,
                  inactiveTrackColor: kTrack,
                  thumbColor: kBrand,
                  overlayColor: kBrand.withOpacity(0.15),
                  valueIndicatorColor: kBrand,
                ),
                child: Slider(
                  value: windowHours.clamp(0, 72),
                  min: 0, max: 72, divisions: 72,
                  label: "${windowHours.round()}h",
                  onChanged: onWindowChanged,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text("${windowHours.round()}h", style: const TextStyle(color: kMuted)),
          ],
        ),
      ],
    );
  }
}