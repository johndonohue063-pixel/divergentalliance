// lib/models/spp_models.dart
import 'dart:convert';

/// ------------------------------
/// Core DTOs used by SPP engine
/// ------------------------------

class CountyInput {
  final String cluster;
  final String county;
  final String state;
  final double probabilityPercent;
  final int population;
  final String? primaryUtilities;     // nullable on input
  final String? stagingSuggestions;   // nullable on input

  CountyInput({
    required this.cluster,
    required this.county,
    required this.state,
    required this.probabilityPercent,
    required this.population,
    this.primaryUtilities,
    this.stagingSuggestions,
  });

  static List<CountyInput> listFromJson(String raw) {
    final data = json.decode(raw);
    if (data is List) {
      // Accept either a list of objects, or a CSV-like first row header + rows
      if (data.isNotEmpty && data.first is Map) {
        return data.cast<Map>().map((m) => CountyInput.fromMap(m.cast<String, dynamic>())).toList();
      }
      if (data.isNotEmpty && data.first is List) {
        // header row then rows
        final header = (data.first as List).map((e) => e.toString()).toList();
        final idx = (String k) => header.indexOf(k);
        final out = <CountyInput>[];
        for (int i = 1; i < data.length; i++) {
          final r = data[i] as List;
          String getS(String k, [String def = '']) {
            final j = idx(k); if (j < 0 || j >= r.length) return def;
            final v = r[j]; return v == null ? def : v.toString();
          }
          double getD(String k, [double def = 0]) {
            final s = getS(k); return double.tryParse(s) ?? def;
          }
          int getI(String k, [int def = 0]) {
            final s = getS(k); return int.tryParse(s) ?? def;
          }
          out.add(CountyInput(
            cluster: getS('cluster', 'US'),
            county: getS('county', 'Unknown'),
            state: getS('state', 'NA'),
            probabilityPercent: getD('probabilityPercent', 0),
            population: getI('population', 0),
            primaryUtilities: getS('primaryUtilities', 'TBD'),
            stagingSuggestions: getS('stagingSuggestions', 'TBD'),
          ));
        }
        return out;
      }
    }
    throw const FormatException('Unsupported CountyInput JSON shape');
  }

  factory CountyInput.fromMap(Map<String, dynamic> m) {
    String s(String k, [String def = '']) => (m[k]?.toString() ?? def);
    double d(String k, [double def = 0]) {
      final v = m[k];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? def;
    }
    int i(String k, [int def = 0]) {
      final v = m[k];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? def;
    }

    return CountyInput(
      cluster: s('cluster', 'US'),
      county: s('county', 'Unknown'),
      state: s('state', 'NA'),
      probabilityPercent: d('probabilityPercent', 0),
      population: i('population', 0),
      primaryUtilities: (m['primaryUtilities']?.toString().isEmpty ?? true) ? 'TBD' : s('primaryUtilities'),
      stagingSuggestions: (m['stagingSuggestions']?.toString().isEmpty ?? true) ? 'TBD' : s('stagingSuggestions'),
    );
  }
}

class CountyOutput {
  final String cluster;
  final String county;
  final String state;
  final double probabilityPercent;
  final int population;
  final String suggestedCrews;
  final double predictedIncidents;
  final int predictedCustomersOut;
  final String threatLevel;
  final String stagingSuggestions;
  final String primaryUtilities;
  final DateTime predictedImpactDate;

  CountyOutput({
    required this.cluster,
    required this.county,
    required this.state,
    required this.probabilityPercent,
    required this.population,
    required this.suggestedCrews,
    required this.predictedIncidents,
    required this.predictedCustomersOut,
    required this.threatLevel,
    required this.stagingSuggestions,
    required this.primaryUtilities,
    required this.predictedImpactDate,
  });
}

/// Crew recommendation rule
class CrewRule {
  final int maxCustomersOut;
  final String line;
  final String support;

  CrewRule({required this.maxCustomersOut, required this.line, required this.support});

  factory CrewRule.fromMap(Map<String, dynamic> m) => CrewRule(
    maxCustomersOut: (m['maxCustomersOut'] is num) ? (m['maxCustomersOut'] as num).toInt() : int.tryParse(m['maxCustomersOut']?.toString() ?? '') ?? 0,
    line: m['line']?.toString() ?? 'TBD',
    support: m['support']?.toString() ?? 'TBD',
  );
}

/// Population cap entry for a probability band
class PopCap {
  final int minPop;
  final int? maxPop;
  final double capRate;
  final double? twoMillionMultiplier; // extra damping for >= 2M

  PopCap({
    required this.minPop,
    this.maxPop,
    required this.capRate,
    this.twoMillionMultiplier,
  });

  bool matches(int pop) {
    final lo = minPop;
    final hi = maxPop ?? 1 << 31;
    return pop >= lo && pop <= hi;
  }

  factory PopCap.fromMap(Map<String, dynamic> m) => PopCap(
    minPop: (m['minPop'] is num) ? (m['minPop'] as num).toInt() : int.tryParse(m['minPop']?.toString() ?? '') ?? 0,
    maxPop: (m['maxPop'] == null)
        ? null
        : ((m['maxPop'] is num) ? (m['maxPop'] as num).toInt() : int.tryParse(m['maxPop']?.toString() ?? '')),
    capRate: (m['capRate'] is num) ? (m['capRate'] as num).toDouble() : double.tryParse(m['capRate']?.toString() ?? '') ?? 0,
    twoMillionMultiplier: (m['twoMillionMultiplier'] == null)
        ? null
        : ((m['twoMillionMultiplier'] is num) ? (m['twoMillionMultiplier'] as num).toDouble() : double.tryParse(m['twoMillionMultiplier']?.toString() ?? '')),
  );
}

class CapBand {
  final double minProb;
  final double maxProb;
  final String type; // 'fixed' or 'scaled'
  final double? probScaleDivisor; // only for 'scaled'
  final List<PopCap> popCaps;

  CapBand({
    required this.minProb,
    required this.maxProb,
    required this.type,
    this.probScaleDivisor,
    required this.popCaps,
  });

  factory CapBand.fromMap(Map<String, dynamic> m) {
    final pcs = (m['popCaps'] as List? ?? const <dynamic>[])
        .map((e) => PopCap.fromMap((e as Map).cast<String, dynamic>()))
        .toList();
    return CapBand(
      minProb: (m['minProb'] is num) ? (m['minProb'] as num).toDouble() : double.tryParse(m['minProb']?.toString() ?? '') ?? 0,
      maxProb: (m['maxProb'] is num) ? (m['maxProb'] as num).toDouble() : double.tryParse(m['maxProb']?.toString() ?? '') ?? 100,
      type: m['type']?.toString() ?? 'fixed',
      probScaleDivisor: (m['probScaleDivisor'] == null)
          ? null
          : ((m['probScaleDivisor'] is num) ? (m['probScaleDivisor'] as num).toDouble() : double.tryParse(m['probScaleDivisor']?.toString() ?? '')),
      popCaps: pcs.isEmpty ? _defaultPopCaps() : pcs,
    );
  }

  static List<PopCap> _defaultPopCaps() => <PopCap>[
    // <100k
    PopCap(minPop: 0,      maxPop:  99999,  capRate: 0.02,   twoMillionMultiplier: null),
    // 100k-499k
    PopCap(minPop: 100000, maxPop: 499999,  capRate: 0.015,  twoMillionMultiplier: null),
    // 500k-999k
    PopCap(minPop: 500000, maxPop: 999999,  capRate: 0.01,   twoMillionMultiplier: 0.85),
    // >=1M
    PopCap(minPop: 1000000,               capRate: 0.008,   twoMillionMultiplier: 0.85),
  ];
}

class SppRuleSet {
  final List<CapBand> capBands;
  final List<(int, int)> level3PopThresholds; // [(popFloor, custsOutThreshold), ...]
  final double level3ProbThreshold;
  final Map<String, int> clusterCeilings;
  final List<CrewRule> crewRules;

  SppRuleSet({
    required this.capBands,
    required this.level3PopThresholds,
    required this.level3ProbThreshold,
    required this.clusterCeilings,
    required this.crewRules,
  });

  factory SppRuleSet.fromJson(Map<String, dynamic> m) {
    // cap bands
    final bands = (m['capBands'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => CapBand.fromMap(e.cast<String, dynamic>()))
        .toList();
    final safeBands = bands.isEmpty ? _defaultBands() : bands;

    // thresholds (records in Dart 3)
    List<(int, int)> tlist = [];
    final rawT = m['level3PopThresholds'];
    if (rawT is List) {
      for (final e in rawT) {
        if (e is List && e.length >= 2) {
          final a = (e[0] is num) ? (e[0] as num).toInt() : int.tryParse(e[0]?.toString() ?? '') ?? 0;
          final b = (e[1] is num) ? (e[1] as num).toInt() : int.tryParse(e[1]?.toString() ?? '') ?? 0;
          tlist.add((a, b));
        } else if (e is Map) {
          final a = (e['pop'] is num) ? (e['pop'] as num).toInt() : int.tryParse(e['pop']?.toString() ?? '') ?? 0;
          final b = (e['threshold'] is num) ? (e['threshold'] as num).toInt() : int.tryParse(e['threshold']?.toString() ?? '') ?? 0;
          tlist.add((a, b));
        }
      }
    }
    if (tlist.isEmpty) {
      // Defaults per your standard rule
      tlist = [
        (2000000, 100000), // >=2M => 100k
        (1000000,  75000), // >=1M => 75k
        (0,        25000), // else => 25k
      ];
    }

    final lvl3Prob = (m['level3ProbThreshold'] is num)
        ? (m['level3ProbThreshold'] as num).toDouble()
        : double.tryParse(m['level3ProbThreshold']?.toString() ?? '') ?? 45.0;

    // ceilings
    final ceilings = <String, int>{};
    final rawC = m['clusterCeilings'];
    if (rawC is Map) {
      rawC.forEach((k, v) {
        ceilings[k.toString()] = (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
      });
    }
    // Always allow Chicagoland default if none present
    ceilings.putIfAbsent('Chicagoland Corridor', () => 90000);

    // crew rules
    final crew = (m['crewRules'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => CrewRule.fromMap(e.cast<String, dynamic>()))
        .toList();
    final safeCrew = crew.isEmpty
        ? <CrewRule>[
      CrewRule(maxCustomersOut: 5000,  line: '10–15 line', support: '4–8 support'),
      CrewRule(maxCustomersOut: 15000, line: '20–30 line', support: '8–15 support'),
      CrewRule(maxCustomersOut: 30000, line: '40–60 line', support: '15–30 support'),
      CrewRule(maxCustomersOut: 60000, line: '60–100 line', support: '25–40 support'),
      CrewRule(maxCustomersOut: 100000,line: '100–150 line', support: '40–60 support'),
      CrewRule(maxCustomersOut: 999999999, line: '150+ line', support: '60+ support'),
    ]
        : crew;

    return SppRuleSet(
      capBands: safeBands,
      level3PopThresholds: tlist,
      level3ProbThreshold: lvl3Prob,
      clusterCeilings: ceilings,
      crewRules: safeCrew,
    );
  }

  // Sensible defaults that match your “Metro Realism” caps
  static List<CapBand> _defaultBands() => <CapBand>[
    // 12–19% scaled by probability
    CapBand(
      minProb: 12, maxProb: 19, type: 'scaled', probScaleDivisor: 16.0,
      popCaps: [
        PopCap(minPop: 0,       maxPop:  99999, capRate: 0.020),
        PopCap(minPop: 100000,  maxPop: 499999, capRate: 0.015),
        PopCap(minPop: 500000,  maxPop: 999999, capRate: 0.010, twoMillionMultiplier: 0.85),
        PopCap(minPop: 1000000,                 capRate: 0.008, twoMillionMultiplier: 0.85),
      ],
    ),
    // 20–29%
    CapBand(
      minProb: 20, maxProb: 29, type: 'fixed',
      popCaps: [
        PopCap(minPop: 0,       maxPop:  99999, capRate: 0.020),
        PopCap(minPop: 100000,  maxPop: 499999, capRate: 0.015),
        PopCap(minPop: 500000,  maxPop: 999999, capRate: 0.010, twoMillionMultiplier: 0.85),
        PopCap(minPop: 1000000,                 capRate: 0.008, twoMillionMultiplier: 0.85),
      ],
    ),
    // 30–44%
    CapBand(
      minProb: 30, maxProb: 44, type: 'fixed',
      popCaps: [
        PopCap(minPop: 0,       maxPop:  99999, capRate: 0.030),
        PopCap(minPop: 100000,  maxPop: 499999, capRate: 0.022),
        PopCap(minPop: 500000,  maxPop: 999999, capRate: 0.015, twoMillionMultiplier: 0.85),
        PopCap(minPop: 1000000,                 capRate: 0.010, twoMillionMultiplier: 0.85),
      ],
    ),
    // >=45%
    CapBand(
      minProb: 45, maxProb: 100, type: 'fixed',
      popCaps: [
        PopCap(minPop: 0,       maxPop:  99999, capRate: 0.040),
        PopCap(minPop: 100000,  maxPop: 499999, capRate: 0.030),
        PopCap(minPop: 500000,  maxPop: 999999, capRate: 0.020, twoMillionMultiplier: 0.85),
        PopCap(minPop: 1000000,                 capRate: 0.013, twoMillionMultiplier: 0.85),
      ],
    ),
  ];
}
