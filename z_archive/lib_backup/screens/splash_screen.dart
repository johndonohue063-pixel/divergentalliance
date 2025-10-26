import 'package:flutter/material.dart';
import '../core/loading_bolt.dart';
import '../services/wx_api.dart';

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
    _go();
  }

  Future<void> _go() async {
    LoadingBolt.show(context);
    try {
      await WxApi.discover();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/truck');
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/truck');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backend not found, $e')),
      );
    } finally {
      LoadingBolt.hide();
    }
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
