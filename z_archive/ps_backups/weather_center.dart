import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/loading_bolt.dart';
import 'services/wx_api.dart';

class WeatherCenter extends StatefulWidget {
  const WeatherCenter({super.key});

  @override
  State<WeatherCenter> createState() => _WeatherCenterState();
}

class _WeatherCenterState extends State<WeatherCenter> {
  // simple inputs
  String _state = 'FL';
  int _maxZones = 25;
  int _threshold = 35;

  Map<String, dynamic>? _report;

  Future<void> _load() async {
    LoadingBolt.show(context);
    try {
      final data = await WxApi.reportNational(
        state: _state,
        maxZones: _maxZones,
        threshold: _threshold,
      );
      if (!mounted) return;
      setState(() => _report = data);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Report loaded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load failed, $e')));
    } finally {
      LoadingBolt.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pretty = _report == null
        ? 'No data yet'
        : const JsonEncoder.withIndent('  ').convert(_report);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Divergent Weather Center'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                WxApi.baseUrl == null ? 'server: unknown' : 'server: ${WxApi.baseUrl}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    initialValue: _state,
                    decoration: const InputDecoration(labelText: 'State'),
                    onChanged: (v) => _state = v.trim().toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: '$_maxZones',
                    decoration: const InputDecoration(labelText: 'Max zones'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) _maxZones = n;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: '$_threshold',
                    decoration: const InputDecoration(labelText: 'Threshold'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null) _threshold = n;
                    },
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Load data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    pretty,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
