import 'package:flutter/material.dart';
import '../widgets/info_card.dart';
import '../widgets/last_route_card.dart';
import 'active_ride_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color laranja = Color(0xFFFF5A1F);
  static const Color preto = Color(0xFF181818);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    'MOTO RIDE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: laranja,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: preto,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Saudação
              const Text(
                'Olá, João!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Pronto para um novo rolê?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              // Área do mapa (Mock Visual)
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 50,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mapa da rota',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Botão INICIAR ROTA (Navega para ActiveRidePage)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActiveRidePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text(
                    'INICIAR ROTA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: laranja,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Resumo / Dados gerais
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InfoCard(
                    icon: Icons.route,
                    valor: '42,3 km',
                    titulo: 'Distância',
                  ),
                  InfoCard(
                    icon: Icons.timer_outlined,
                    valor: '58 min',
                    titulo: 'Tempo',
                  ),
                  InfoCard(
                    icon: Icons.speed,
                    valor: '43,7 km/h',
                    titulo: 'Média',
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Text(
                'Último percurso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const LastRouteCard(),
            ],
          ),
        ),
      ),
    );
  }
}