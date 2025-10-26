// lib/services/wx_api.dart
import 'dart:async';
import 'dart:io' show Platform;
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:http/http.dart' as http;

class WxApi {
  WxApi._();

  static String? _base;

  /// Call from initState() once. You can pass an override during testing.
  static void discover({String? overrideBase}) {
    _base = overrideBase ?? _defaultBase();
    // >>> HARD BOOT MARKER <<<
    // ignore: avoid_print
    print('[WxApi:BOOT] base=$baseUrl');
  }

  static String _defaultBase() {
    if (kIsWeb) return 'http://localhost:8010';
    if (Platform.isAndroid) return 'http://10.0.2.2:8010'; // Android emulator
    return 'http://127.0.0.1:8010'; // iOS sim / desktop
  }

  static String get baseUrl => _base ?? _defaultBase();

  static const _timeout = Duration(seconds: 60);

  /// Keep only non-null, non-empty params.
  static Map<String, String> _qp(Map<String, Object?> src) {
    final out = <String, String>{};
    src.forEach((k, v) {
      if (v == null) return;
      final s = v.toString().trim();
      if (s.isEmpty) return;
      out[k] = s;
    });
    return out;
  }

  /// Build a URI and sanitize query:
  /// - Mirror wind_mph -> threshold (backend gates on 'threshold')
  /// - If days_out present, set horizon_hours = days_out*24 and drop timeline
  /// - Remove empty horizon_hours and any empty keys
  static Uri _build(String path, Map<String, Object?> qp) {
    final m = Map<String, Object?>.from(qp);

    // 1) threshold follows UI wind mph
    if (m['wind_mph'] != null) {
      m['threshold'] = m['wind_mph'];
    }

    // 2) days_out wins; convert to hours and ignore timeline if present
    final daysStr = m['days_out']?.toString().trim();
    final days = daysStr == null ? null : int.tryParse(daysStr);
    if (days != null && days > 0) {
      m['horizon_hours'] = days * 24;
      m.remove('timeline');
    }

    // 3) drop empty horizon_hours
    final hh = m['horizon_hours']?.toString().trim();
    if (hh == null || hh.isEmpty) m.remove('horizon_hours');

    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: _qp(m));

    // --- TRIPWIRE: fail fast if the URL is wrong ---
    final q = uri.query;
    if (q.contains('timeline=')) {
      // ignore “timeline” entirely; Days Out must drive horizon
      // ignore: avoid_print
      print('[TRIPWIRE] timeline leaked into request: $uri');
      throw StateError('timeline leaked into request; Days Out must be used');
    }
    if (q.contains('horizon_hours=&')) {
      // ignore: avoid_print
      print('[TRIPWIRE] empty horizon_hours leaked: $uri');
      throw StateError('empty horizon_hours leaked');
    }
    // Threshold must match wind_mph (UI “Wind mph (min)”)
    final wind = m['wind_mph']?.toString();
    if (wind != null && wind.isNotEmpty && !q.contains('threshold=$wind')) {
      // ignore: avoid_print
      print('[TRIPWIRE] threshold not mirrored to wind_mph: $uri');
      throw StateError('threshold not equal to wind_mph');
    }
    // --- END TRIPWIRE ---

    // HARD LOG of the final URL you are actually sending
    // ignore: avoid_print
    print('[WxApi:FINAL] $uri');

    return uri;
  }

  static Future<String> _getText(Uri uri, {Map<String, String>? headers}) async {
    final res = await http.get(uri, headers: headers).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.reasonPhrase}');
    }
    return res.body;
  }

  /// Main call used by the Weather Center. Requests CSV for speed.
  ///
  /// Pass the UI "Wind mph (min)" as [windMphMin].
  /// Pass the UI "Days out" as [daysOut].
  /// If the user explicitly selects custom hours, pass that in [explicitHours]
  /// and DO NOT send days_out.
  static Future<List<Map<String, dynamic>>> nationalSmart({
    required String region,
    required int maxZones,
    required int windMphMin,  // UI "Wind mph (min)"
    required int daysOut,     // UI "Days out"
    int? explicitHours,       // only when user picks custom hours
    String? state,
  }) async {
    final uri = nationalRequestUri(
      region: region,
      maxZones: maxZones,
      windMphMin: windMphMin,
      daysOut: daysOut,
      explicitHours: explicitHours,
      state: state,
      format: 'csv',
    );

    final csvText = await _getText(uri, headers: const {'Accept': 'text/csv'});
    final rows = await compute(_parseCsvToMaps, csvText);
    return rows;
  }

  /// Build a national request URI.
  /// If [explicitHours] is provided, send horizon_hours; else send days_out.
  static Uri nationalRequestUri({
    required String region,
    required int maxZones,
    required int windMphMin,  // used for BOTH threshold and wind_mph
    required int daysOut,
    int? explicitHours,
    String? state,
    String format = 'csv',
  }) {
    return _build('/report/national', {
      'region': region,
      'max_zones': maxZones,
      'wind_mph': windMphMin,             // _build() mirrors to threshold
      if (explicitHours != null) 'horizon_hours': explicitHours,
      if (explicitHours == null) 'days_out': daysOut,
      'state': (state?.trim().isEmpty ?? true) ? null : state!.trim(),
      'format': format,
    });
  }

  static Uri nationalCsvUri({
    required String region,
    required int maxZones,
    required int windMphMin,
    required int daysOut,
    int? explicitHours,
    String? state,
  }) =>
      nationalRequestUri(
        region: region,
        maxZones: maxZones,
        windMphMin: windMphMin,
        daysOut: daysOut,
        explicitHours: explicitHours,
        state: state,
        format: 'csv',
      );
}

/// Top-level so it can run inside `compute(...)`.
List<Map<String, dynamic>> _parseCsvToMaps(String csvText) {
  if (csvText.trim().isEmpty) return const [];
  final rows = const CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false, // keep all as strings; UI does its own parsing
  ).convert(csvText);

  if (rows.isEmpty) return const [];

  final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
  final out = <Map<String, dynamic>>[];

  for (var i = 1; i < rows.length; i++) {
    final r = rows[i];
    if (r.isEmpty) continue;
    final m = <String, dynamic>{};
    for (var j = 0; j < header.length && j < r.length; j++) {
      m[header[j]] = r[j];
    }
    out.add(m);
  }
  return out;
}
