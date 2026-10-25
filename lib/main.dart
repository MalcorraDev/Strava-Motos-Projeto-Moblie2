
import 'package:flutter/material.dart';
import 'screens/main_navigation_wrapper.dart';

void main() {
  runApp(const MotoRideApp());
}

class MotoRideApp extends StatelessWidget {
  const MotoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Ride',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
          secondary: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationWrapper(),
    );
  }
}
