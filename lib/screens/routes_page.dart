import 'package:flutter/material.dart';
import '../models/route_model.dart';
import 'home_page.dart';
import 'route_detail_page.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final List<RouteModel> _routes = [
    RouteModel(
      id: '1',
      title: 'Rota da Fronteira',
      distance: '42,3 km',
      duration: '58 min',
      avgSpeed: '43,7 km/h',
      maxSpeed: '89,0 km/h',
      movingTime: '50 min',
      stoppedTime: '8 min',
      date: '24/09/2026',
      bike: 'Yamaha MT-03',
      isSavedOffline: true,
    ),
    RouteModel(
      id: '2',
      title: 'Serra do Rio do Rastro',
      distance: '112,0 km',
      duration: '2h 15min',
      avgSpeed: '49,8 km/h',
      maxSpeed: '95,4 km/h',
      movingTime: '1h 55min',
      stoppedTime: '20 min',
      date: '15/08/2026',
      bike: 'Honda CB 500X',
      isSavedOffline: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Rotas e Viagens', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _routes.length,
        itemBuilder: (context, index) {
          final item = _routes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteDetailPage(
                      routeName: item.title,
                      distance: item.distance,
                      duration: item.duration,
                      avgSpeed: item.avgSpeed,
                      maxSpeed: item.maxSpeed,
                      movingTime: item.movingTime,
                      stoppedTime: item.stoppedTime,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _routes.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    Text('${item.date} • ${item.bike}', style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.distance} • ${item.duration}'),
                        Row(
                          children: [
                            Icon(
                              item.isSavedOffline ? Icons.offline_pin : Icons.download_for_offline_outlined,
                              color: item.isSavedOffline ? HomePage.laranja : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isSavedOffline ? 'Salvo Offline' : 'Baixar',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.isSavedOffline ? HomePage.laranja : Colors.grey,
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}