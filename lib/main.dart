import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const GoodEatsApp());

class GoodEatsApp extends StatelessWidget {
  const GoodEatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // P04 Consistency: one seed color + Material 3 for every screen.
    return MaterialApp(
      title: 'Good Eats',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFE8572A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
