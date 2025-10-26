import 'package:flutter/material.dart';
import '../ui/da_button.dart';
import 'truck_landing.dart';
import 'weather_center.dart';
// import 'weather_center_pro.dart';
import 'weather_center_restored.dart';
import 'shop_under_construction.dart';
import 'package:divergent_alliance/screens/weather_center_gate.dart' as gate;
import 'package:divergent_alliance/screens/weather_center_pro.dart';


class DevMenu extends StatelessWidget {
  const DevMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Divergent Alliance')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
                child: Text(''),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const Placeholder()))),
            ElevatedButton(
                child: Text(''),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const gate.WeatherCenterGate()))),
            ElevatedButton(
                child: Text(''),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SizedBox.shrink()))),
            ElevatedButton(
                child: Text(''),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const WeatherCenterRestored()))),
            ElevatedButton(
                child: Text(''),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ShopUnderConstruction()))),
          ],
        ),
      ),
    );
  }
}
