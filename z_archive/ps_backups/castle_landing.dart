import 'package:flutter/material.dart';

class CastleLanding extends StatelessWidget {
  const CastleLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain, // show entire image, never crop
              alignment: Alignment.center,
              child: Image.asset(
                "assets/images/background.png",
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text("Background image missing",
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shop coming soon')),
                          );
                        },
                        child: const Text('Shop'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/weather'),
                        child: const Text('Divergent Weather Center'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
