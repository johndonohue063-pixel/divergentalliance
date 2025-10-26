import 'dart:convert';
import 'package:http/http.dart' as http;

/// Live NOAA/NWS-backed weather API.
/// Uses api.weather.gov points + hourly forecast. No dummy data.
class WxApi {
  final _ua = 'DivergentAllianceApp/1.0 (mobile)';

  Future<_PointMeta> _points(double lat, double lon) async {
    final url = Uri.parse('https://api.weather.gov/points/$lat,$lon');
    final r = await http.get(url, headers: {'User-Agent': _ua, 'Accept': 'application/geo+json'});
    if (r.statusCode != 200) { throw Exception('NWS points failed: ${r.statusCode}'); }
    final j = json.decode(r.body);
    final props = j['properties'] ?? {};
    final rel = props['relativeLocation']?['properties'] ?? {};
    return _PointMeta(
      gridId: props['gridId'],
      gridX: props['gridX'],
      gridY: props['gridY'],
      city: rel['city'] ?? 'Unknown',
      state: rel['state'] ?? '',
      forecastHourly: props['forecastHourly'],
    );
  }

  Future<_Hourly> _hourly(String forecastHourlyUrl) async {
    final r = await http.get(Uri.parse(forecastHourlyUrl), headers: {'User-Agent': _ua, 'Accept': 'application/geo+json'});
    if (r.statusCode != 200) { throw Exception('NWS hourly failed: ${r.statusCode}'); }
    final j = json.decode(r.body);
    final periods = j['properties']?['periods'] as List? ?? const [];
    final out = <HourSample>[];
    for (final p in periods) {
      final t  = p['startTime'] as String? ?? '';
      final ws = _parseMph(p['windSpeed']);
      final wg = _parseMph(p['windGust']);
      out.add(HourSample(timeIso: t, sustainedMph: ws, gustMph: wg));
    }
    return _Hourly(samples: out);
  }

  static int _parseMph(dynamic field){
    if(field == null) return 0;
    final s = field.toString(); // "15 mph" or "20 to 25 mph"
    final parts = s.split(' ');
    if(parts.isEmpty) return 0;
    final first = int.tryParse(parts.first) ?? 0;
    if (s.contains('to')) {
      for (final p in parts) {
        final v = int.tryParse(p);
        if (v != null && v > first) return v;
      }
    }
    return first;
  }

  /// PUBLIC: live summary for given lat/lon
  Future<LiveSummary> liveSummary({required double lat, required double lon}) async {
    final meta = await _points(lat, lon);
    final h = await _hourly(meta.forecastHourly);
    final now = h.samples.isNotEmpty ? h.samples.first : HourSample(timeIso: '', sustainedMph: 0, gustMph: 0);
    return LiveSummary(
      city: meta.city, state: meta.state,
      sustainedMph: now.sustainedMph,
      gustMph: now.gustMph,
      hourly: h.samples,
    );
  }
}

class _PointMeta {
  final String gridId; final int gridX; final int gridY;
  final String city; final String state; final String forecastHourly;
  _PointMeta({required this.gridId, required this.gridX, required this.gridY, required this.city, required this.state, required this.forecastHourly});
}

class _Hourly { final List<HourSample> samples; _Hourly({required this.samples}); }

class HourSample {
  final String timeIso;
  final int sustainedMph;
  final int gustMph;
  HourSample({required this.timeIso, required this.sustainedMph, required this.gustMph});
}

class LiveSummary {
  final String city; final String state;
  final int sustainedMph; final int gustMph;
  final List<HourSample> hourly;
  LiveSummary({required this.city, required this.state, required this.sustainedMph, required this.gustMph, required this.hourly});
}
