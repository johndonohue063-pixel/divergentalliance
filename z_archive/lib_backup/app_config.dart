import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

const String _apiOverride =
String.fromEnvironment('WX_API_BASE', defaultValue: '');
const String _stormOverride =
String.fromEnvironment('WX_STORM_UI_PATH', defaultValue: '/app/#/storm'); // your Storm UI route
const String _csvOverride =
String.fromEnvironment('WX_CSV_PATH', defaultValue: '/report/national?threshold=35&max_zones=200&format=csv');

String apiBase() {
  if (_apiOverride.isNotEmpty) return _apiOverride;
  // Android emulator cannot reach 127.0.0.1 on your PC, use the special alias:
  try { if (Platform.isAndroid) return 'http://10.0.2.2:8050'; } catch (_) {}
  return 'http://127.0.0.1:8050';
}

String stormUiPath() => _stormOverride.startsWith('/') ? _stormOverride : '/$_stormOverride';
String csvPath()     => _csvOverride.startsWith('/')   ? _csvOverride   : '/$_csvOverride';
