import 'package:flutter/material.dart';
import '../screens/home_page.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String titulo;

  const InfoCard({
    super.key,
    required this.icon,
    required this.valor,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: HomePage.laranja,
          size: 28,
        ),
        const SizedBox(height: 6),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}