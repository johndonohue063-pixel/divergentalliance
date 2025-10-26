import 'package:flutter/material.dart';
import '../services/wx_service.dart';

enum WindMetric { gust, sustained }

class WxProCounty {
  final String fips;
  final String name;
  final String state;
  final double lat;
  final double lon;
  const WxProCounty({required this.fips, required this.name, required this.state, required this.lat, required this.lon});
}

const List<WxProCounty> wxProCounties = [
  WxProCounty(fips:'17031', name:'Cook',      state:'IL', lat:41.84, lon:-87.65),
  WxProCounty(fips:'36061', name:'New York',  state:'NY', lat:40.78, lon:-73.97),
  WxProCounty(fips:'12086', name:'Miami-Dade',state:'FL', lat:25.61, lon:-80.53),
];

class WxProRow {
  final WxProCounty county;
  final double gust;
  final double sustained;
  final int severity;
  final int crew;
  WxProRow(this.county, this.gust, this.sustained, this.severity, this.crew);
}

int wxProSeverityFor(double gust, double sustained){
  final s = gust >= sustained ? gust : sustained;
  if (s >= 75) return 5;
  if (s >= 58) return 4;
  if (s >= 46) return 3;
  if (s >= 34) return 2;
  if (s >= 20) return 1;
  return 0;
}

int wxProCrewFor(int severity, double mph){
  if (severity == 0) return 0;
  if (severity == 1) return 1;
  if (severity == 2) return 2;
  if (severity == 3) return 4;
  if (severity == 4) return 6;
  return 8;
}

void wxProRunReport(BuildContext context){
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const WxProRunSheet(),
  );
}

class WxProRunSheet extends StatefulWidget {
  const WxProRunSheet({super.key});
  @override
  State<WxProRunSheet> createState() => _WxProRunSheetState();
}

class _WxProRunSheetState extends State<WxProRunSheet> {
  bool _busy = false;
  int _windowHours = 72;
  WindMetric _metric = WindMetric.gust;
  int _minSeverity = 0;

  List<WxProRow> _rows = [];
  double _expG = 0, _expS = 0; 
  int _maxSev = 0; 
  int _crew = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState((){ _busy = true; _rows = []; _expG=0; _expS=0; _maxSev=0; _crew=0;});
    try {
      final List<WxProRow> rows = [];
      double g=0, s=0; int sev=0;

      for (final c in wxProCounties) {
        final w = await WxService.fetchWind(lat:c.lat, lon:c.lon, windowHours:_windowHours);
        final sLevel = wxProSeverityFor(w.maxGustMph, w.maxSustainedMph);
        if (sLevel < _minSeverity) continue;
        final crews = wxProCrewFor(sLevel, (w.maxGustMph >= w.maxSustainedMph ? w.maxGustMph : w.maxSustainedMph));
        rows.add(WxProRow(c, w.maxGustMph, w.maxSustainedMph, sLevel, crews));
        if (w.maxGustMph > g) g = w.maxGustMph;
        if (w.maxSustainedMph > s) s = w.maxSustainedMph;
        if (sLevel > sev) sev = sLevel;
      }

      rows.sort((a,b){
        final av = _metric == WindMetric.gust ? a.gust : a.sustained;
        final bv = _metric == WindMetric.gust ? b.gust : b.sustained;
        return bv.compareTo(av);
      });

      setState((){
        _rows = rows;
        _expG = g; _expS = s; _maxSev = sev; 
        _crew = rows.isNotEmpty ? rows.first.crew : 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Run failed: $e')));
    } finally {
      if (mounted) setState(()=> _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16,16,16,24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.play_arrow),
              const SizedBox(width:8),
              const Text('Run Report', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: _busy ? null : _run, icon: const Icon(Icons.refresh)),
            ]),
            const SizedBox(height:8),
            Wrap(spacing:12, runSpacing:12, children: [
              _tile('Expected Gust','${_expG.toStringAsFixed(0)} mph', Icons.air),
              _tile('Expected Sust.','${_expS.toStringAsFixed(0)} mph', Icons.wind_power),
              _tile('Severity','Level $_maxSev', Icons.warning_amber),
              _tile('Crew Rec','$_crew crews', Icons.groups),
            ]),
            const SizedBox(height:12),

            const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            const Text('Wind Metric'),
            Wrap(spacing:8, children:[
              ChoiceChip(label: const Text('Gust'), selected: _metric == WindMetric.gust, onSelected: (_){ setState(()=>_metric=WindMetric.gust); _run(); }),
              ChoiceChip(label: const Text('Sustained'), selected: _metric == WindMetric.sustained, onSelected: (_){ setState(()=>_metric=WindMetric.sustained); _run(); }),
            ]),
            const SizedBox(height:8),
            const Text('Minimum Threat Level'),
            Wrap(spacing:8, children: List<Widget>.generate(6, (i) => ChoiceChip(
              label: Text('Min Sev $i'),
              selected: _minSeverity==i,
              onSelected: (_){ setState(()=>_minSeverity=i); _run(); },
            ))),
            const SizedBox(height:8),
            Row(children:[
              const Text('Window (hours)'),
              Expanded(child: Slider(
                value: _windowHours.toDouble(),
                min: 12, max: 168, divisions: 13, label: '$_windowHours',
                onChanged: (v)=> setState(()=> _windowHours = v.round()),
                onChangeEnd: (_)=> _run(),
              )),
              Text('$_windowHours'),
            ]),
            const SizedBox(height:12),

            if (_busy) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
            if (!_busy) _rows.isEmpty
              ? const Text('No results match the filters.')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const Divider(height:1),
                  itemBuilder: (_, i){
                    final r = _rows[i];
                    return ListTile(
                      dense: true,
                      title: Text('${r.county.name}, ${r.county.state}'),
                      subtitle: Text('Gust: ${r.gust.toStringAsFixed(0)} mph  •  Sustained: ${r.sustained.toStringAsFixed(0)} mph'),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Sev ${r.severity}'),
                        Text('${r.crew} crews'),
                      ]),
                    );
                  }),
          ]),
        ),
      ),
    );
  }

  Widget _tile(String label, String value, IconData icon){
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.15),
      ),
      child: Row(children:[
        Icon(icon),
        const SizedBox(width:8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
          Text(label),
          const SizedBox(height:4),
          Text(value, style: const TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
        ])),
      ]),
    );
  }
}