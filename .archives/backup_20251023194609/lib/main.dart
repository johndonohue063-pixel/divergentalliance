import "ui/da_brand.dart";
import 'package:flutter/material.dart';
import 'package:divergent_alliance/screens/castle_landing.dart';
import 'screens/weather_center_pro.dart';

void main() => runApp(const DivergentApp());

class DivergentApp extends StatelessWidget {
  const DivergentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        canvasColor: const Color(0xFF0E0E0E),
        cardColor: const Color(0xFF121212),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
              primary: DABrand.orange,
              secondary: DABrand.orange,
              surface: const Color(0xFF121212),
              onPrimary: Colors.black,
              onSurface: Colors.white,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DABrand.orange,
            foregroundColor: DABrand.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: DABrand.orange),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: DABrand.orange,
            side: const BorderSide(color: DABrand.orange, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      title: 'Divergent Alliance',
      home: const CastleLanding(),
      routes: {
        '/weather': (context) => const WeatherCenterPro(),
      },
    );
  }
}
