import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WxApi {
  static String? _base;

  static Future<void> discover() async {
    final hosts = <String>[
      if (Platform.isAndroid) ...['http://10.0.2.2:8010','http://10.0.2.2:8000'],
      'http://127.0.0.1:8010','http://127.0.0.1:8000',
    ];
    for (final h in hosts) {
      try {
        final r = await http.get(Uri.parse('\/health')).timeout(const Duration(seconds: 2));
        if (r.statusCode == 200) { _base = h; return; }
      } catch (_) {}
    }
  }

  static Future<Map<String,dynamic>> _get(String path) async {
    if (_base == null) {
      return {
        'demo': true,
        'message': 'Backend not reachable, showing demo data',
        'time': DateTime.now().toIso8601String(),
        'report': {'state':'FL','max_zones':25,'threshold':35,'counties':[]}
      };
    }
    final uri = Uri.parse('');
    final r = await http.get(uri).timeout(const Duration(seconds: 30));
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final dec = json.decode(r.body.isEmpty ? '{}' : r.body);
      return dec is Map<String,dynamic> ? dec : {'data': dec};
    }
    throw HttpException('GET \ failed \');
  }

  static Future<Map<String,dynamic>> reportNational({String state='FL', int maxZones=25, int threshold=35})
    => _get('/report/national?state=\&max_zones=\&threshold=\');

  static Future<Map<String,dynamic>> reportQuick({required double lat, required double lon})
    => _get('/report/quick?lat=\&lon=\');

  static String? get baseUrl => _base;
}
