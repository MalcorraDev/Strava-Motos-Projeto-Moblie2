import 'package:flutter/material.dart';
import '../services/strava_api.dart';
import 'active_ride_page.dart';
import 'routes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color laranja = Color(0xFFFF5A1F);
  static const Color preto = Color(0xFF181818);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final trips = await StravaApi.listarViagens();
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDuration(num? seconds) {
    final total = seconds?.toInt() ?? 0;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '$minutes min';
  }

  String _formatDistance(num? distance) =>
      (distance ?? 0).toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final totalDistance = _trips.fold<double>(
      0,
      (sum, trip) => sum + ((trip['distancia_km'] as num?)?.toDouble() ?? 0),
    );
    final totalSeconds = _trips.fold<int>(
      0,
      (sum, trip) => sum + ((trip['duracao_segundos'] as num?)?.toInt() ?? 0),
    );
    final lastTrip = _trips.isEmpty ? null : _trips.first;
    final lastBike = lastTrip?['motocicletas'];
    final lastBikeName = lastBike is Map ? lastBike['modelo']?.toString() : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTrips,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MOTO RIDE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HomePage.laranja,
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: HomePage.preto,
                      child: Icon(Icons.two_wheeler, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                const Text(
                  'Olá, motociclista!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Pronto para um novo rolê?',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 46, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Mapa e rastreamento GPS ainda não disponíveis',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActiveRidePage(),
                        ),
                      );
                      _loadTrips();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'CONFIGURAR ROTA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomePage.laranja,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cloud_off, color: Colors.red),
                      title: const Text('Não foi possível carregar o resumo'),
                      subtitle: Text(_error!),
                      trailing: IconButton(
                        onPressed: _loadTrips,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Summary(icon: Icons.route, value: '${_formatDistance(totalDistance)} km', label: 'Distância'),
                      _Summary(icon: Icons.timer_outlined, value: _formatDuration(totalSeconds), label: 'Tempo'),
                      _Summary(icon: Icons.two_wheeler, value: '${_trips.length}', label: 'Viagens'),
                    ],
                  ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Última viagem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoutesPage()));
                      },
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const LinearProgressIndicator()
                else if (lastTrip == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Nenhuma viagem salva ainda. Suas viagens aparecerão aqui.'),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: HomePage.preto,
                        child: Icon(Icons.two_wheeler, color: HomePage.laranja),
                      ),
                      title: Text(lastTrip['titulo']?.toString() ?? 'Viagem'),
                      subtitle: Text(
                        '${_formatDistance(lastTrip['distancia_km'] as num?)} km • '
                        '${_formatDuration(lastTrip['duracao_segundos'] as num?)}\n'
                        '${lastBikeName ?? 'Moto não informada'}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: HomePage.laranja, size: 28),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  );
}
