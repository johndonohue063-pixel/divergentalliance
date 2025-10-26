import 'dart:math';

class ForecastSample {
  final DateTime ts;
  final double sustainedMph;
  final double gustMph;
  final String source;   // e.g. HRRR, GFS, NBM, NWS, ECMWF
  ForecastSample(this.ts, this.sustainedMph, this.gustMph, this.source);
}

class ForecastAggregate {
  final DateTime windowStart;
  final DateTime windowEnd;
  final double avgSustainedMph;
  final double avgGustMph;
  final double expectedSustainedMph; // trimmed mean
  final double expectedGustMph;       // trimmed mean
  final Map<String, double> sourceWeights; // for transparency
  ForecastAggregate({
    required this.windowStart,
    required this.windowEnd,
    required this.avgSustainedMph,
    required this.avgGustMph,
    required this.expectedSustainedMph,
    required this.expectedGustMph,
    required this.sourceWeights,
  });
}

class GeoProfile {
  final String name; // county or valley
  final double orographicShieldFactor; // 0 to 1, multiply wind for shielded directions
  final List<DirectionalRule> rules;
  GeoProfile({
    required this.name,
    required this.orographicShieldFactor,
    required this.rules,
  });
}

class DirectionalRule {
  final double fromDeg; // inclusive
  final double toDeg;   // inclusive
  final double multiplier; // e.g. 0.8 west events into Champlain
  const DirectionalRule(this.fromDeg, this.toDeg, this.multiplier);
  bool matches(double deg) {
    if (fromDeg <= toDeg) return deg >= fromDeg && deg <= toDeg;
    // wrap across 360
    return deg >= fromDeg || deg <= toDeg;
  }
}

/// Pluggable fetchers, fill these with your real calls in wx_api.dart etc.
abstract class WxSource {
  String get name;
  Future<List<ForecastSample>> fetch({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
  });
}

/// Example fusion engine
class WxFusionEngine {
  final List<WxSource> sources;
  WxFusionEngine(this.sources);

  /// directionDeg is the dominant wind direction during peak window
  Future<ForecastAggregate> fuse({
    required double lat,
    required double lon,
    required DateTime start,
    required DateTime end,
    required GeoProfile geo,
    required double directionDeg,
  }) async {
    final all = <ForecastSample>[];
    for (final s in sources) {
      try {
        final rows = await s.fetch(lat: lat, lon: lon, start: start, end: end);
        all.addAll(rows);
      } catch (_) {/* keep going */}
    }
    if (all.isEmpty) {
      return ForecastAggregate(
        windowStart: start,
        windowEnd: end,
        avgSustainedMph: 0,
        avgGustMph: 0,
        expectedSustainedMph: 0,
        expectedGustMph: 0,
        sourceWeights: const {},
      );
    }

    // group by source for weighting
    final bySource = <String, List<ForecastSample>>{};
    for (final r in all) {
      bySource.putIfAbsent(r.source, () => []).add(r);
    }

    // equal weight per source by default
    final weights = <String, double>{ for (final k in bySource.keys) k: 1.0 };
    final sustainedVals = <double>[];
    final gustVals = <double>[];

    bySource.forEach((_, list) {
      final sAvg = list.map((e) => e.sustainedMph).reduce((a, b) => a + b) / list.length;
      final gAvg = list.map((e) => e.gustMph).reduce((a, b) => a + b) / list.length;
      sustainedVals.add(sAvg);
      gustVals.add(gAvg);
    });

    // simple mean
    final meanS = sustainedVals.reduce((a, b) => a + b) / sustainedVals.length;
    final meanG = gustVals.reduce((a, b) => a + b) / gustVals.length;

    // trimmed mean for expected values, drop high and low if many sources
    double trimmedMean(List<double> xs) {
      if (xs.length <= 2) {
        return xs.reduce((a, b) => a + b) / xs.length;
      }
      final sorted = [...xs]..sort();
      final trim = max(1, (sorted.length * 0.15).floor());
      final middle = sorted.sublist(trim, sorted.length - trim);
      return middle.reduce((a, b) => a + b) / middle.length;
    }

    var expectedS = trimmedMean(sustainedVals);
    var expectedG = trimmedMean(gustVals);

    // apply geography adjustment
    final mult = _geoMultiplier(geo, directionDeg);
    expectedS *= mult;
    expectedG *= mult;

    return ForecastAggregate(
      windowStart: start,
      windowEnd: end,
      avgSustainedMph: meanS,
      avgGustMph: meanG,
      expectedSustainedMph: expectedS,
      expectedGustMph: expectedG,
      sourceWeights: weights,
    );
  }

  double _geoMultiplier(GeoProfile geo, double directionDeg) {
    // default no change
    var m = 1.0;
    for (final r in geo.rules) {
      if (r.matches(directionDeg)) {
        m *= r.multiplier;
      }
    }
    // clamp for safety
    return m.clamp(0.5, 1.25);
  }
}
