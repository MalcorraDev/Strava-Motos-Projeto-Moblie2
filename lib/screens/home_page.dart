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
    final lastBikeName = lastBike is Map
        ? lastBike['modelo']?.toString()
        : null;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTrips,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HomePage.preto,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.two_wheeler, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Olá, motociclista 👋',
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Que tal colocar a estrada no roteiro?',
                  style: TextStyle(fontSize: 14, color: Color(0xFF827B77)),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 190,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF181818), Color(0xFF34302E)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -15,
                        bottom: -32,
                        child: Icon(
                          Icons.route_rounded,
                          size: 190,
                          color: HomePage.laranja.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: HomePage.laranja.withValues(alpha: 0.17),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'SEU PRÓXIMO ROLÊ',
                                style: TextStyle(
                                  color: HomePage.laranja,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 13),
                            const Text(
                              'A estrada\nte espera.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Registre cada quilômetro do passeio.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
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
                      'COMEÇAR VIAGEM',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomePage.laranja,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
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
                      Expanded(
                        child: _Summary(
                          icon: Icons.route_rounded,
                          value: '${_formatDistance(totalDistance)} km',
                          label: 'DISTÂNCIA',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Summary(
                          icon: Icons.timer_outlined,
                          value: _formatDuration(totalSeconds),
                          label: 'TEMPO',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Summary(
                          icon: Icons.two_wheeler,
                          value: '${_trips.length}',
                          label: 'VIAGENS',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Última viagem',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RoutesPage()),
                        );
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
                      child: Text(
                        'Nenhuma viagem salva ainda. Suas viagens aparecerão aqui.',
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: HomePage.preto,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.two_wheeler,
                            color: HomePage.laranja,
                          ),
                        ),
                        title: Text(
                          lastTrip['titulo']?.toString() ?? 'Viagem',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${_formatDistance(lastTrip['distancia_km'] as num?)} km  •  '
                          '${_formatDuration(lastTrip['duracao_segundos'] as num?)}\n'
                          '${lastBikeName ?? 'Moto não informada'}',
                        ),
                        isThreeLine: true,
                      ),
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
  const _Summary({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 104),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: HomePage.laranja, size: 22),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8B8582),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );
}
