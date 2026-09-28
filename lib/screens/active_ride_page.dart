import 'package:flutter/material.dart';
import 'home_page.dart';
import 'route_detail_page.dart';

class ActiveRidePage extends StatefulWidget {
  const ActiveRidePage({super.key});

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  bool isPaused = false;
  bool isMoving = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.preto,
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa Mock
            Positioned.fill(
              child: Container(
                color: const Color(0xFF242424),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, size: 80, color: HomePage.laranja),
                    SizedBox(height: 10),
                    Text(
                      'Rastreamento por GPS Ativo',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    Text(
                      'Gravação em segundo plano habilitada',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isMoving ? Icons.directions_run : Icons.pause_circle_outline,
                          color: isMoving ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMoving ? 'Em Movimento' : 'Parado',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Text(
                      'GPS: Alta Precisão',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Painel Inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('0.00', 'KM', 'Distância'),
                        _buildStat('00:00:00', 'TEMPO', 'Duração'),
                        _buildStat('0.0', 'KM/H', 'Velocidade'),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isPaused = !isPaused;
                                isMoving = !isPaused;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPaused ? Colors.green : Colors.amber.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              isPaused ? 'RETOMAR' : 'PAUSAR',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RouteDetailPage(
                                    routeName: 'Nova Corrida Registrada',
                                    distance: '15.4 km',
                                    duration: '22 min',
                                    avgSpeed: '42.0 km/h',
                                    maxSpeed: '78.5 km/h',
                                    movingTime: '19 min',
                                    stoppedTime: '3 min',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'FINALIZAR',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String unit, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: HomePage.preto),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: HomePage.laranja),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}