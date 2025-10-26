import 'package:flutter/material.dart';
import '../widgets/da_button_compat.dart';

class CastleLanding extends StatelessWidget {
  const CastleLanding({super.key});

  void _runForecast(BuildContext context) {
    debugPrint('Run Forecast from CastleLanding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Castle Landing')),
      body: const Center(child: Text('Castle Landing')),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DAButton(
            onPressed: () => _runForecast(context),
            child: const Text('Run Forecast'),
          ),
        ),
      ),
    );
  }
}
