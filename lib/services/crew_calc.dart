class SeverityBand {
  final String level; // Level 1..4
  final double minGust;      // mph
  final double minSustained; // mph
  const SeverityBand(this.level, this.minGust, this.minSustained);
}

// tune to your book
const _bands = <SeverityBand>[
  SeverityBand('Level 1', 30, 18),
  SeverityBand('Level 2', 45, 25),
  SeverityBand('Level 3', 58, 35),
  SeverityBand('Level 4', 75, 45),
];

String classifySeverity(double expectedGust, double expectedSustained) {
  String out = 'Level 0';
  for (final b in _bands) {
    if (expectedGust >= b.minGust || expectedSustained >= b.minSustained) {
      out = b.level;
    }
  }
  return out;
}

// Simple baseline crew planning per county, plug your full SPP caps as needed
int recommendCrews({
  required int population,
  required double probability,    // 0..1 wind outage probability
  required double expectedGust,   // mph
  required double expectedSustained, // mph
}) {
  // base from probability and population
  final raw = population * probability * 0.002; // tune base rate
  // wind intensity bump
  final bump = 1.0 +
      (expectedGust >= 58 ? 0.35 : expectedGust >= 45 ? 0.2 : expectedGust >= 30 ? 0.1 : 0.0) +
      (expectedSustained >= 35 ? 0.2 : expectedSustained >= 25 ? 0.1 : 0.0);

  // metro realism sample, reduce for very large counties by cap, you can insert your full table here
  var crews = (raw * bump).round();
  if (population >= 2000000) crews = (crews * 0.85).round();
  if (population >= 1000000) crews = (crews * 0.9).round();

  return crews.clamp(0, 9999);
}
