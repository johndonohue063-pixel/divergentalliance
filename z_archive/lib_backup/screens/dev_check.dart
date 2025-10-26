import 'package:flutter/material.dart';
import '../services/wx_api.dart';

class DevCheckScreen extends StatefulWidget {
  const DevCheckScreen({super.key});
  @override
  State<DevCheckScreen> createState() => _DevCheckScreenState();
}

class _DevCheckScreenState extends State<DevCheckScreen> {
  final api = WxApi();
  String out = 'press a button';
  void _set(Object v) => setState(() => out = v.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Divergent API check')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              ElevatedButton(onPressed: () async => _set(await api.health()), child: const Text('Health')),
              ElevatedButton(onPressed: () async { final r = await api.resolve(29.76, -95.37); _set({'county': r.county.name, 'utils': r.utilities.map((u) => u.name).toList()}); }, child: const Text('Resolve HOU')),
              ElevatedButton(onPressed: () async { final fx = await api.forecastPoint(29.76, -95.37); _set({'periods': fx.periods.take(3).map((p) => '${p.name}: ${p.shortText} wind ${p.wind}').toList()}); }, child: const Text('Forecast HOU')),
              ElevatedButton(onPressed: () async { final alerts = await api.alertsByState('TX'); _set(alerts.take(5).map((a) => '${a.event} ${a.severity}').toList()); }, child: const Text('Alerts TX')),
              ElevatedButton(onPressed: () async { final rows = await api.threats(minProb: 12); _set(rows.take(5).toList()); }, child: const Text('Threats')),
            ]),
            const SizedBox(height: 12),
            Expanded(child: SingleChildScrollView(child: SelectableText(out, style: const TextStyle(fontFamily: 'monospace')))),
          ],
        ),
      ),
    );
  }
}
