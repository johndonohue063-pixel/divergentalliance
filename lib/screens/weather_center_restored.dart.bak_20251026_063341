import 'package:flutter/material.dart';
import '../ui/da_button.dart';
import '../services/wx_api.dart';

class WeatherCenterRestored extends StatefulWidget {
  const WeatherCenterRestored({super.key});
  @override
  State<WeatherCenterRestored> createState() => _WeatherCenterRestoredState();
}

class _WeatherCenterRestoredState extends State<WeatherCenterRestored> {
  final _windCtl = TextEditingController(text: '45');
  final _hoursCtl = TextEditingController(text: '72');
  bool _busy = false;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void dispose() {
    _windCtl.dispose();
    _hoursCtl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final w = int.tryParse(_windCtl.text) ?? 45;
    final h = int.tryParse(_hoursCtl.text) ?? 72;
    setState(() {
      _busy = true;
    });
    try {
      _rows = await WxApi.national(windMph: w, horizonHours: h);
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Weather Center (Restored)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                    child: TextField(
                  controller: _windCtl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Wind â‰¥ mph',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70)),
                  ),
                )),
                const SizedBox(width: 16),
                Expanded(
                    child: TextField(
                  controller: _hoursCtl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Horizon hours',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70)),
                  ),
                )),
              ]),
              const SizedBox(height: 16),
              DAButton(
                  label: _busy ? 'LOADINGâ€¦' : 'FETCH',
                  onPressed: _busy ? null : _fetch),
              const SizedBox(height: 16),
              Expanded(
                child: _rows.isEmpty
                    ? const Center(
                        child: Text('No rows yet',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (ctx, i) {
                          final r = _rows[i];
                          return ListTile(
                            title: Text(' â€” ',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Wind â‰¥ mph:    Horizon: ',
                                style: const TextStyle(color: Colors.white70)),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.white54),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
