import 'package:flutter/material.dart';
import 'services/wx_api.dart';
import 'weather_center.dart';
import 'castle_landing.dart' show CastleLanding;

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
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF38B2B), // brand orange
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // NOTE: no navigatorObservers here (we removed the route flash)
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/truck': (_) => CastleLanding(),        // keep non-const if you prefer
        '/weather': (_) => const WeatherCenter(),
      },
    );
  }
}

/// One clean splash: spin logo, discover backend, then land on truck screen.
/// No LoadingBolt here so the logo is never covered.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await WxApi.discover();                         // find backend (10.0.2.2 on emulator)
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {
      // keep going regardless
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/truck');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFF38B2B);
    final logo = Image.asset(
      'assets/images/logo.png',
      width: 140,
      height: 140,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.flash_on, size: 140, color: brand),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: RotationTransition(turns: _c, child: logo)),
    );
  }
}
