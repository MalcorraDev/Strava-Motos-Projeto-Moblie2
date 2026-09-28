import 'package:flutter/material.dart';
import 'screens/home_page.dart';
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
        primaryColor: Colors.orange, // Alterado para cor padrão do Flutter
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,  // Alterado para cor padrão do Flutter
          primary: Colors.orange,    // Alterado para cor padrão do Flutter
          secondary: Colors.black,   // Alterado para cor padrão do Flutter
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationWrapper(),
    );
  }
}
