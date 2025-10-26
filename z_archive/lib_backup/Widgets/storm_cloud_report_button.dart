import 'dart:math';
import 'package:flutter/material.dart';

import '../services/spp_engine.dart';
import '../models/spp_models.dart';

class StormCloudReportButton extends StatefulWidget {
  const StormCloudReportButton({
    super.key,
    this.httpEndpoint,
    this.apiKey,
    this.useLocalSample = true,
  });

  final String? httpEndpoint;
  final String? apiKey;
  final bool useLocalSample;

  @override
  State<StormCloudReportButton> createState() => _StormCloudReportButtonState();
}

class _StormCloudReportButtonState extends State<StormCloudReportButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  bool _running = false;
  String _label = 'Divergent Prediction Report';

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _label = 'Running…';
    });

    try {
      final rules = await SppEngine.loadRules();
      final src = widget.useLocalSample
          ? LocalSppDataSource()
          : HttpSppDataSource(
        endpoint: widget.httpEndpoint!,
        apiKey: widget.apiKey,
      );
      final engine = SppEngine(dataSource: src, rules: rules);
      await engine.run(onLog: (m) {
        if (mounted) setState(() => _label = m);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SPP complete, CSV and chart saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SPP failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _running = false;
        _label = 'Divergent Prediction Report';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Run Divergent Prediction Report',
      child: GestureDetector(
        onTap: _running ? null : _run,
        child: AnimatedBuilder(
          animation: _ac,
          builder: (context, _) {
            final pulse = 1.0 + 0.02 * sin(_ac.value * pi * 2);
            return Transform.scale(
              scale: pulse,
              child: _CloudVisual(label: _label, raining: _running),
            );
          },
        ),
      ),
    );
  }
}

class _CloudVisual extends StatelessWidget {
  const _CloudVisual({required this.label, required this.raining});
  final String label;
  final bool raining;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // soft glow
        Container(
          width: 220,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.12),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // cloud body
        CustomPaint(
          size: const Size(220, 130),
          painter: _CloudPainter(),
        ),
        // optional rain hint while running
        if (raining)
          Positioned(
            bottom: 32,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                6,
                    (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 3,
                  height: 10 + (i % 3) * 4,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade400.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        // label
        Positioned(
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ground shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.15, h * 0.62, w * 0.7, h * 0.18),
        const Radius.circular(12),
      ),
      shadowPaint,
    );

    // cloud gradient
    final cloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEFEFF3),
          Color(0xFFD8DBE2),
          Color(0xFFBCC1CA),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // cloud shape, overlapping puffs, plus a base
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.30, h * 0.48), radius: h * 0.28))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.52, h * 0.40), radius: h * 0.34))
      ..addOval(Rect.fromCircle(center: Offset(w * 0.72, h * 0.50), radius: h * 0.26))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.50, w * 0.64, h * 0.28),
        const Radius.circular(24),
      ));

    // soft rim
    final rim = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, rim);

    // fill
    canvas.drawPath(path, cloudPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
