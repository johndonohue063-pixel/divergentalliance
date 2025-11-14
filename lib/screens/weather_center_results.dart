import 'package:flutter/material.dart';

class WeatherCenterResults extends StatelessWidget {
  const WeatherCenterResults({
    super.key,
    required this.rows,
    this.showDetails = true,
  });

  final List<Map<String, dynamic>> rows;
  final bool showDetails;

  static const _kBg = Color(0xFF0E0E0E);
  static const _kPanel = Color(0xFF141414);
  static const _kOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: rows.isEmpty
            ? const Center(
            child: Text('No results yet.',
                style: TextStyle(color: Colors.white70)))
            : _table(rows),
      ),
    );
  }

  Widget _table(List<Map<String, dynamic>> rows) {
    final cols = <String>[
      'County',
      'State',
      'Expected Gust',
      'Expected Sustained',
      'Severity',
      'Suggested Crews',
    ].where((c) => rows.first.containsKey(c)).toList();

    return Container(
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOrange.withOpacity(0.25), width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dividerThickness: 0.6,
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600),
          dataTextStyle: const TextStyle(color: Colors.white),
          columns: cols.map((c) => DataColumn(label: Text(c))).toList(),
          rows: rows
              .map((r) => DataRow(
            cells:
            cols.map((c) => DataCell(Text('${r[c]}'))).toList(),
          ))
              .toList(),
        ),
      ),
    );
  }
}
