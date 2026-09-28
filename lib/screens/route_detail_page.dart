import 'package:flutter/material.dart';
import 'home_page.dart';

class RouteDetailPage extends StatelessWidget {
  final String routeName;
  final String distance;
  final String duration;
  final String avgSpeed;
  final String maxSpeed;
  final String movingTime;
  final String stoppedTime;

  const RouteDetailPage({
    super.key,
    required this.routeName,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.movingTime,
    required this.stoppedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routeName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 60, color: HomePage.laranja),
                  SizedBox(height: 8),
                  Text('Mapa do Percurso Concluído', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Estatísticas da Viagem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            _buildDetailTile(Icons.straighten, 'Distância Total', distance),
            _buildDetailTile(Icons.timer, 'Tempo Total', duration),
            _buildDetailTile(Icons.directions_run, 'Tempo em Movimento', movingTime),
            _buildDetailTile(Icons.pause_circle_filled, 'Tempo Parado', stoppedTime),
            _buildDetailTile(Icons.speed, 'Velocidade Média', avgSpeed),
            _buildDetailTile(Icons.bolt, 'Velocidade Máxima', maxSpeed),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: HomePage.laranja),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}