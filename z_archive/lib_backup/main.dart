// lib/main.dart
import 'package:flutter/material.dart';
import 'weather_center.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DivergentApp());
}

class DivergentApp extends StatelessWidget {
  const DivergentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divergent Alliance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF38B2B),
          brightness: Brightness.dark,
        ),
      ),
      home: const LandingScreen(),
      routes: {
        WeatherCenter.route: (_) => const WeatherCenter(),
      },
    );
  }
}

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Hero / “bucket truck” area ---
            Positioned.fill(
              child: Opacity(
                opacity: 0.20,
                child: Image.asset(
                  'assets/images/bucket_truck.jpg', // keep your existing asset path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // --- Content ---
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Divergent Alliance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Utility Ops • Weather Intelligence • Rapid Response',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.cloud),
                          label: const Text('Open Weather Center'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            backgroundColor: scheme.secondaryContainer,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pushNamed(context, WeatherCenter.route),

                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Store (coming soon)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Store is coming soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
