import 'package:flutter/material.dart';
import 'widgets/da_bubble_button.dart';

class CastleLanding extends StatefulWidget {
  const CastleLanding({super.key});

  @override
  State<CastleLanding> createState() => _CastleLandingState();
}

class _CastleLandingState extends State<CastleLanding> {
  final ImageProvider _bg = const AssetImage('assets/images/truck_hero.png');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_bg, context);
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFF38B2B);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: _bg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Text(
                'Truck image not found, check assets path',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          // Darken for legibility
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          // Buttons pinned to bottom
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: DABubbleButton(
                        label: 'Shop',
                        icon: Icons.storefront,
                        onPressed: () {},
                        filled: true,
                        brand: brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DABubbleButton(
                        label: 'Weather Center',
                        icon: Icons.bolt,
                        onPressed: () => Navigator.pushNamed(context, '/weather'),
                        filled: true,
                        brand: brand,
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
