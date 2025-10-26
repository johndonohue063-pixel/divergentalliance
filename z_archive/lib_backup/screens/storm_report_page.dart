import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

// Backend URL: web -> 127.0.0.1, Android emulator -> 10.0.2.2
// in storm_report_page.dart
String get kBaseUrl => 'http://127.0.0.1:8000';  // or 8010 if you used that


const Map<String, List<String>> kRegions = {
  'All US': [],
  'Northeast': ['ME','NH','VT','MA','RI','CT','NY','NJ','PA'],
  'Southeast': ['DC','DE','MD','VA','WV','NC','SC','GA','FL','AL','MS','TN','KY'],
  'Midwest'  : ['OH','MI','IN','IL','WI','MN','IA','MO','ND','SD','NE','KS'],
  'South'    : ['TX','OK','AR','LA'],
  'Southwest': ['AZ','NM','UT','NV'],
  'West'     : ['CA','OR','WA','ID','MT','WY','CO'],
  'Alaska'   : ['AK'],
  'Hawaii'   : ['HI'],
  'Caribbean': ['PR','VI'],
  'Pacific'  : ['GU','AS','MP'],
};

class StormReportPage extends StatefulWidget {
  final String? defaultRegion;   // e.g. 'Southeast'
  final String? defaultState;    // e.g. 'FL'
  final int?    defaultMaxZones; // e.g. 150
  final int     defaultThreshold; // mph
  final bool    autoRun;

  const StormReportPage({
    super.key,
    this.defaultRegion,
    this.defaultState,
    this.defaultMaxZones,
    this.defaultThreshold = 50,
    this.autoRun = false,
  });

  @override
  State<StormReportPage> createState() => _StormReportPageState();
}

class _StormReportPageState extends State<StormReportPage> {
  // filters
  String _region = 'All US';
  String _state  = 'ALL'; // ALL = all states in the region
  final _maxZonesCtl = TextEditingController(text: '150');
  double _threshold = 50;

  // results
  bool _loading = false;
  String? _error;
  int _count = 0;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _region = widget.defaultRegion ?? _region;
    _state  = widget.defaultState  ?? _state;
    if (widget.defaultMaxZones != null) _maxZonesCtl.text = widget.defaultMaxZones!.toString();
    _threshold = widget.defaultThreshold.toDouble();
    if (widget.autoRun) WidgetsBinding.instance.addPostFrameCallback((_) => _runReport());
  }

  List<DropdownMenuItem<String>> _buildStateItems() {
    final states = kRegions[_region]!;
    final items = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'ALL', child: Text(states.isEmpty ? 'All states' : 'All states in $_region')),
    ];
    items.addAll(states.map((s) => DropdownMenuItem(value: s, child: Text(s))));
    return items;
  }

  Future<void> _runReport() async {
    setState(() { _loading = true; _error = null; _rows = []; _count = 0; });
    try {
      final qp = <String, String>{ 'threshold': _threshold.round().toString() };
      final mz = _maxZonesCtl.text.trim(); if (mz.isNotEmpty) qp['max_zones'] = mz;

      // state takes priority; else region (unless All US)
      if (_state != 'ALL') {
        qp['state'] = _state;
      } else if (_region != 'All US') {
        qp['region'] = _region;
      }

      final uri = Uri.parse('$kBaseUrl/report/national').replace(queryParameters: qp);
      final r = await http.get(uri, headers: {'User-Agent': 'Divergent-Mobile'});
      if (r.statusCode != 200) throw Exception('Backend ${r.statusCode}: ${r.body}');
      final js = json.decode(r.body) as Map<String, dynamic>;
      _count = (js['count'] ?? 0) as int;

      final rows = (js['rows'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // sort: most hours >= threshold, then by max wind
      rows.sort((a, b) {
        final ah = (a['hours_wind_ge_threshold'] ?? 0) as int;
        final bh = (b['hours_wind_ge_threshold'] ?? 0) as int;
        if (bh != ah) return bh.compareTo(ah);
        final am = (a['max_wind_mph'] ?? 0) as int;
        final bm = (b['max_wind_mph'] ?? 0) as int;
        return bm.compareTo(am);
      });

      setState(() { _rows = rows; });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _openCsv() async {
    final qp = <String, String>{ 'threshold': _threshold.round().toString() };
    final mz = _maxZonesCtl.text.trim(); if (mz.isNotEmpty) qp['max_zones'] = mz;
    if (_state != 'ALL') {
      qp['state'] = _state;
    } else if (_region != 'All US') {
      qp['region'] = _region;
    }
    final url = Uri.parse('$kBaseUrl/report/national.csv').replace(queryParameters: qp).toString();
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final states = kRegions[_region]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Storm Prediction Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filters: Region -> State -> Max zones
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _region,
                  items: kRegions.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() { _region = v; _state = 'ALL'; }); // reset state when region changes
                  },
                  decoration: const InputDecoration(labelText: 'Region'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: (_state == 'ALL' || states.contains(_state)) ? _state : 'ALL',
                  items: _buildStateItems(),
                  onChanged: (v) => setState(() => _state = v ?? 'ALL'),
                  decoration: InputDecoration(labelText: 'State${_region == 'All US' ? ' (optional)' : ''}'),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _maxZonesCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max zones'),
                ),
              ),
            ]),

            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text('Wind threshold: ${_threshold.round()} mph', style: theme.textTheme.bodyMedium)),
            ]),
            Slider(min: 30, max: 90, divisions: 60, label: '${_threshold.round()}',
                value: _threshold, onChanged: (v) => setState(() => _threshold = v)),

            Row(children: [
              ElevatedButton.icon(onPressed: _loading ? null : _runReport, icon: const Icon(Icons.bolt), label: const Text('Run Storm Prediction')),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: _rows.isEmpty ? null : _openCsv, icon: const Icon(Icons.download), label: const Text('Open CSV')),
              const SizedBox(width: 12),
              if (_count > 0) Text('Count: $_count'),
            ]),

            if (_loading) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),

            const SizedBox(height: 8),
            Expanded(
              child: _rows.isEmpty
                  ? Center(
                child: Text(
                  _loading ? 'Running report...' : 'No rows returned. Try another region/state,\nraise Max zones, or lower the threshold.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
                  : ListView.separated(
                itemCount: _rows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = _rows[i];
                  final title = '${r['county'] ?? 'Unknown'}, ${r['state'] ?? ''}';
                  final maxWind = r['max_wind_mph'];
                  final hours   = r['hours_wind_ge_threshold'];
                  final fte     = r['fte_flag'] == true;
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('Max ${maxWind ?? 'N/A'} mph, hours ≥ thresh: ${hours ?? 0}'),
                    trailing: fte ? const Chip(label: Text('FTE')) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

