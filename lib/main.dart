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
        primaryColor: HomePage.laranja,
        colorScheme: ColorScheme.fromSeed(
          seedColor: HomePage.laranja,
          primary: HomePage.laranja,
          secondary: HomePage.preto,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationWrapper(),
    );
  }
}