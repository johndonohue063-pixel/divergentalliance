// lib/services/spp_engine.dart
//
// NOAA and NWS live pull, Census enrichment, compute rules, emit one CSV.
// Web triggers a browser download, native writes to app docs directory.

import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import '../models/spp_models.dart';

// Conditional import, no op on native, real download on web
import 'web_download_stub.dart'
if (dart.library.html) 'web_download_html.dart' as webdl;

/// ------------------------------
/// Data sources
/// ------------------------------

abstract class SppDataSource {
  Future<List<CountyInput>> fetchInputs(DateTime anchorDate);
}

/// Local sample, handy for testing without network
class LocalSppDataSource implements SppDataSource {
  final String assetPath;
  LocalSppDataSource({this.assetPath = 'assets/spp/sample_counties.json'});

  @override
  Future<List<CountyInput>> fetchInputs(DateTime anchorDate) async {
    final raw = await rootBundle.loadString(assetPath);
    return CountyInput.listFromJson(raw);
  }
}

/// Live NWS and Census
class NwsNoaaLiveDataSource implements SppDataSource {
  static const List<String> _events = [
    'High Wind Warning',
    'High Wind Watch',
    'Wind Advisory',
    'Hurricane Warning',
    'Hurricane Watch',
    'Tropical Storm Warning',
    'Tropical Storm Watch',
    'Severe Thunderstorm Warning',
    'Severe Thunderstorm Watch',
  ];

  static const Map<String, int> _eventProb = {
    'Hurricane Warning': 70,
    'Hurricane Watch': 55,
    'Tropical Storm Warning': 55,
    'Tropical Storm Watch': 40,
    'High Wind Warning': 55,
    'High Wind Watch': 40,
    'Wind Advisory': 30,
    'Severe Thunderstorm Warning': 40,
    'Severe Thunderstorm Watch': 35,
  };

  static const Map<String, String> _stateFipsToAbbr = {
    '01':'AL','02':'AK','04':'AZ','05':'AR','06':'CA','08':'CO','09':'CT','10':'DE','11':'DC',
    '12':'FL','13':'GA','15':'HI','16':'ID','17':'IL','18':'IN','19':'IA','20':'KS','21':'KY',
    '22':'LA','23':'ME','24':'MD','25':'MA','26':'MI','27':'MN','28':'MS','29':'MO','30':'MT',
    '31':'NE','32':'NV','33':'NH','34':'NJ','35':'NM','36':'NY','37':'NC','38':'ND','39':'OH',
    '40':'OK','41':'OR','42':'PA','44':'RI','45':'SC','46':'SD','47':'TN','48':'TX','49':'UT',
    '50':'VT','51':'VA','53':'WA','54':'WV','55':'WI','56':'WY'
  };

  @override
  Future<List<CountyInput>> fetchInputs(DateTime anchorDate) async {
    // ---------------- 1) Pull active alerts (hardened, with fallback) ----------------
    final int limit = kIsWeb ? 500 : 1000;
    final headers = <String, String>{'Accept': 'application/geo+json'};

    http.Response alertsResp = await http.get(
      Uri.parse('https://api.weather.gov/alerts/active?limit=$limit'),
      headers: headers,
    );

    // Fallback to /alerts?status=actual if /active rejects us
    if (alertsResp.statusCode != 200) {
      alertsResp = await http.get(
        Uri.parse('https://api.weather.gov/alerts?status=actual&limit=$limit'),
        headers: headers,
      );
    }

    if (alertsResp.statusCode != 200) {
      final body = alertsResp.body;
      final snippet = body.isEmpty ? '' : body.substring(0, body.length > 160 ? 160 : body.length);
      throw Exception('NWS Alerts HTTP ${alertsResp.statusCode}${snippet.isEmpty ? '' : ': $snippet'}');
    }

    final Map<String, dynamic> alertsJson =
    json.decode(alertsResp.body) as Map<String, dynamic>;
    final List features = (alertsJson['features'] as List?) ?? <dynamic>[];

    // ---------------- 2) Collect SAME county codes, keep max prob + earliest onset ----
    final Map<String, int> fipsToProb = {};
    final Map<String, DateTime> fipsToDate = {};

    for (final f in features) {
      final props = (f is Map ? f['properties'] : null) as Map<String, dynamic>? ?? const {};
      final event = (props['event'] ?? '') as String;
      if (!_events.contains(event)) continue;

      final geocode = (props['geocode'] ?? const {}) as Map<String, dynamic>;
      final sameRaw = geocode['SAME'];

      // SAME can be a List or a String; normalize to List<String>
      final List<String> same = switch (sameRaw) {
        List l => l.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList(),
        String s when s.isNotEmpty => [s],
        _ => const <String>[],
      };
      if (same.isEmpty) continue;

      final String onsetStr = (props['onset'] ?? props['effective'] ?? '').toString();
      DateTime? onset;
      if (onsetStr.isNotEmpty) {
        try { onset = DateTime.parse(onsetStr); } catch (_) {}
      }

      final baseProb = _eventProb[event] ?? 30;

      for (final s in same) {
        final String code = s.toString(); // 0 + state(2) + county(3)
        if (code.length != 6) continue;
        final cur = fipsToProb[code];
        if (cur == null || baseProb > cur) fipsToProb[code] = baseProb;
        if (onset != null) {
          final ex = fipsToDate[code];
          if (ex == null || onset.isBefore(ex)) fipsToDate[code] = onset;
        }
      }
    }

    if (fipsToProb.isEmpty) return <CountyInput>[];

    // ---------------- 3) Census county names and pops ---------------------------------
    final censusResp = await http.get(Uri.parse(
      'https://api.census.gov/data/2023/acs/acs1?get=NAME,B01003_001E&for=county:*&in=state:*',
    ));
    if (censusResp.statusCode != 200) {
      throw Exception('Census API HTTP ${censusResp.statusCode}');
    }
    final List<dynamic> rows = json.decode(censusResp.body) as List<dynamic>;
    final Map<String, (String name, int pop, String stateFips, String countyFips)> fipsMap = {};
    for (int i = 1; i < rows.length; i++) {
      final List r = rows[i] as List;
      final name = r[0].toString();
      final pop = int.tryParse(r[1].toString()) ?? 0;
      final stateF = r[2].toString().padLeft(2, '0');
      final countyF = r[3].toString().padLeft(3, '0');
      final code = '0$stateF$countyF'; // SAME style "0SSCCC"
      fipsMap[code] = (name, pop, stateF, countyF);
    }

    // ---------------- 4) Build CountyInput --------------------------------------------
    final List<CountyInput> out = [];
    for (final e in fipsToProb.entries) {
      final code = e.key;
      final prob = e.value;
      final c = fipsMap[code];
      if (c == null) continue;

      final fullName = c.$1; // "Autauga County, Alabama"
      final pop = c.$2;
      final stateFips = c.$3;
      final abbr = _stateFipsToAbbr[stateFips] ?? '';

      final comma = fullName.indexOf(',');
      final rawCounty = comma > 0 ? fullName.substring(0, comma) : fullName;
      final countyClean = rawCounty
          .replaceAll(' County', '')
          .replaceAll(' Parish', '')
          .replaceAll(' Borough', '')
          .replaceAll(' Census Area', '')
          .replaceAll(' Municipality', '')
          .trim();

      final date = fipsToDate[code];
      final onsetStr = date == null
          ? 'TBD'
          : 'Onset ${date.toIso8601String().split('T').first}';

      out.add(
        CountyInput(
          cluster: 'US',
          county: countyClean.isEmpty ? 'Unknown' : countyClean,
          state: abbr.isEmpty ? 'NA' : abbr,
          probabilityPercent: prob.toDouble(),
          population: pop,
          primaryUtilities: 'TBD',
          stagingSuggestions: onsetStr,
        ),
      );
    }

    return out;
  }
}

/// Optional remote source shaped like the sample JSON
class HttpSppDataSource implements SppDataSource {
  final String endpoint;
  final String? apiKey;
  HttpSppDataSource({required this.endpoint, this.apiKey});

  @override
  Future<List<CountyInput>> fetchInputs(DateTime anchorDate) async {
    final uri = Uri.parse('$endpoint?anchorDate=${anchorDate.toIso8601String()}');
    final headers = <String, String>{
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      'Accept': 'application/json',
    };
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} fetching inputs');
    }
    return CountyInput.listFromJson(resp.body);
  }
}

/// ------------------------------
/// Engine
/// ------------------------------

class SppEngine {
  final SppDataSource dataSource;
  final SppRuleSet rules;

  SppEngine({required this.dataSource, required this.rules});

  static Future<SppRuleSet> loadRules({void Function(String log)? onLog}) async {
    void log(String m) { if (onLog != null) onLog(m); }
    try {
      final raw = await rootBundle.loadString('assets/spp/spp_rules.json');
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return SppRuleSet.fromJson(decoded);
      } else {
        log('Rules JSON not an object, using defaults');
        return SppRuleSet.fromJson(<String, dynamic>{});
      }
    } catch (e) {
      log('loadRules failed: $e — using defaults');
      return SppRuleSet.fromJson(<String, dynamic>{});
    }
  }

  /// Runs, computes, filters L2 and L3, emits one CSV
  Future<void> run({DateTime? anchorDate, void Function(String log)? onLog}) async {
    final anchor = anchorDate ?? DateTime.now();
    void log(String m) { if (onLog != null) onLog(m); }

    try {
      log('Fetching live NOAA NWS inputs');
      final inputs = await dataSource.fetchInputs(anchor);
      log('Inputs: ${inputs.length} counties');

      log('Computing results');
      final allRows = inputs.map((c) => _computeCounty(c, anchor)).toList();

      log('Applying ceilings and metro realism');
      final capped = _applyClusterCeilings(allRows);

      log('Filtering Level 2 and Level 3');
      final alerts = _alertsOnly(capped);

      final csv = _toCsv(alerts);
      final ts = _ts(anchor);
      final filename = 'spp_alerts_US_$ts.csv';

      if (kIsWeb) {
        final safeName = filename.isEmpty ? 'report.csv' : filename;
        final safeCsv  = csv.isEmpty ? 'Cluster,County,State\n' : csv;
        await webdl.downloadTextFileWeb(safeName, safeCsv);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$filename').writeAsString(csv);
    } catch (e, st) {
      log('SPP run failed: $e');
      log(st.toString().split('\n').take(5).join('\n'));
      rethrow;
    }
  }

  CountyOutput _computeCounty(CountyInput c, DateTime anchor) {
    final prob = c.probabilityPercent.clamp(0, 100).toDouble();
    final pop = max(0, c.population);

    final customersOut = _computeCustomersOut(pop, prob);
    final incidents = _incidentEstimate(customersOut, prob);
    final crews = _crewSuggestion(customersOut);
    final threat = _threatLevel(prob, customersOut, pop);

    // derive impact date from stagingSuggestions if present
    DateTime impactDate = anchor;
    final s = (c.stagingSuggestions ?? '').trim();
    if (s.startsWith('Onset ')) {
      final d = s.substring(6).trim();
      try { impactDate = DateTime.parse(d); } catch (_) {}
    }

    return CountyOutput(
      cluster: c.cluster,
      county: c.county,
      state: c.state,
      probabilityPercent: prob,
      population: pop,
      suggestedCrews: crews.isEmpty ? 'TBD' : crews,
      predictedIncidents: incidents,
      predictedCustomersOut: customersOut,
      threatLevel: threat,
      stagingSuggestions: s.isEmpty ? 'TBD' : s,
      primaryUtilities: (c.primaryUtilities ?? '').isEmpty ? 'TBD' : c.primaryUtilities!,
      predictedImpactDate: impactDate,
    );
  }

  double _incidentEstimate(int customersOut, double probPercent) {
    int cpi;
    if (probPercent >= 45) {
      cpi = 500;
    } else if (probPercent >= 30) {
      cpi = 700;
    } else if (probPercent >= 20) {
      cpi = 900;
    } else {
      cpi = 1200;
    }
    return customersOut / cpi;
  }

  int _computeCustomersOut(int pop, double probPercent) {
    final rawOut = pop * (probPercent / 100.0);
    if (rules.capBands.isEmpty) return rawOut.round();

    final band = rules.capBands.firstWhere(
          (b) => probPercent >= b.minProb && probPercent <= b.maxProb,
      orElse: () => rules.capBands.last,
    );
    final pc = band.popCaps.firstWhere(
          (p) => p.matches(pop),
      orElse: () => band.popCaps.last,
    );

    double capRate = pc.capRate;
    if (pop >= 2000000 && pc.twoMillionMultiplier != null) {
      capRate *= pc.twoMillionMultiplier!;
    }

    final capValue = (band.type == 'scaled')
        ? pop * capRate * (probPercent / (band.probScaleDivisor ?? 16.0))
        : pop * capRate;

    return min(rawOut, capValue).round();
  }

  String _crewSuggestion(int customersOut) {
    for (final r in rules.crewRules) {
      if (customersOut <= r.maxCustomersOut) return '${r.line}, ${r.support}';
    }
    return 'TBD';
  }

  String _threatLevel(double probPercent, int customersOut, int pop) {
    if (probPercent >= rules.level3ProbThreshold) return 'Level 3';
    int elev = 25000;
    for (final t in rules.level3PopThresholds) {
      if (pop >= t.$1) elev = t.$2;
    }
    if (customersOut >= elev) return 'Level 3';
    if (probPercent >= 30 || customersOut >= 10000) return 'Level 2';
    return 'Level 1';
  }

  List<CountyOutput> _applyClusterCeilings(List<CountyOutput> rows) {
    final byCluster = <String, List<CountyOutput>>{};
    for (final r in rows) {
      byCluster.putIfAbsent(r.cluster, () => []).add(r);
    }

    final out = <CountyOutput>[];
    byCluster.forEach((cluster, list) {
      final ceiling = rules.clusterCeilings[cluster];
      if (ceiling == null) { out.addAll(list); return; }
      final sum = list.fold<int>(0, (a, b) => a + b.predictedCustomersOut);
      if (sum <= ceiling) { out.addAll(list); return; }
      final factor = ceiling / sum;
      for (final r in list) {
        out.add(
          CountyOutput(
            cluster: r.cluster,
            county: r.county,
            state: r.state,
            probabilityPercent: r.probabilityPercent,
            population: r.population,
            suggestedCrews: r.suggestedCrews,
            predictedIncidents: r.predictedIncidents * factor,
            predictedCustomersOut: (r.predictedCustomersOut * factor).round(),
            threatLevel: r.threatLevel,
            stagingSuggestions: r.stagingSuggestions,
            primaryUtilities: r.primaryUtilities,
            predictedImpactDate: r.predictedImpactDate,
          ),
        );
      }
    });
    return out;
  }

  List<CountyOutput> _alertsOnly(List<CountyOutput> rows) =>
      rows.where((r) => r.threatLevel == 'Level 2' || r.threatLevel == 'Level 3').toList();

  String _toCsv(List<CountyOutput> rows) {
    final data = <List<dynamic>>[
      [
        'Cluster','County','State','Wind Outage Probability %','Population',
        'Suggested Crews','Predicted Incidents','Predicted Customers Out','Threat Level',
        'Staging Suggestions','Primary + Secondary Utilities','Predicted Impact Date',
      ],
    ];
    for (final r in rows) {
      data.add([
        r.cluster, r.county, r.state,
        r.probabilityPercent.toStringAsFixed(0),
        r.population,
        r.suggestedCrews,
        r.predictedIncidents.toStringAsFixed(2),
        r.predictedCustomersOut,
        r.threatLevel,
        r.stagingSuggestions,
        r.primaryUtilities,
        r.predictedImpactDate.toIso8601String().split('T').first,
      ]);
    }
    return const ListToCsvConverter().convert(data);
  }

  String _ts(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}_${two(dt.hour)}${two(dt.minute)}${two(dt.second)}';
  }
}
