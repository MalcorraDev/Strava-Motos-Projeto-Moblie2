import 'package:flutter/material.dart';

import '../services/strava_api.dart';
import 'active_ride_page.dart';
import 'routes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color laranja = Color(0xFFFF5A1F);
  static const Color preto = Color(0xFF121316);
  static const Color painel = Color(0xFF1A1C20);
  static const Color borda = Color(0xFF292C32);
  static const Color verde = Color(0xFF12D69A);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _bikes = [];
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _premium = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    List<Map<String, dynamic>> trips = [];
    List<Map<String, dynamic>> bikes = [];
    Map<String, dynamic>? profile;
    String? error;
    try {
      trips = await StravaApi.listarViagens();
    } catch (exception) {
      error = exception.toString().replaceFirst('Exception: ', '');
    }
    try {
      bikes = await StravaApi.listarMotos();
    } catch (_) {
      // Preserve the dashboard data if the garage request fails independently.
    }
    try {
      profile = await StravaApi.perfil();
    } catch (_) {
      // Unknown subscription state always falls back to Free.
    }

    if (!mounted) return;
    setState(() {
      _trips = trips;
      _bikes = bikes;
      _profile = profile;
      _premium = profile?['premium'] == true;
      _error = error;
      _loading = false;
    });
  }

  String _formatDuration(num? seconds) {
    final total = seconds?.toInt() ?? 0;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatDistance(num? distance) =>
      (distance ?? 0).toStringAsFixed(1).replaceAll('.', ',');

  String _firstName() {
    final name = _profile?['nome']?.toString().trim();
    if (name == null || name.isEmpty) return 'Piloto';
    return name.split(RegExp(r'\s+')).first;
  }

  Future<void> _startRide() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ActiveRidePage()),
    );
    if (mounted) await _loadDashboard();
  }

  void _openRoutes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RoutesPage()),
    );
  }

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
    final relatedBike = lastTrip?['motocicletas'];
    final lastBikeName = relatedBike is Map
        ? relatedBike['modelo']?.toString()
        : null;
    final bike = _bikes.isEmpty ? null : _bikes.first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          color: HomePage.laranja,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: [
              _topBar(),
              const SizedBox(height: 24),
              const _Eyebrow('PAINEL DO PILOTO'),
              const SizedBox(height: 7),
              Text(
                'Boa estrada, ${_firstName()}.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Sua garagem e suas viagens, em um só lugar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              _connectionStrip(),
              const SizedBox(height: 18),
              _vehiclePanel(context, bike),
              const SizedBox(height: 12),
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _startRide,
                  icon: const Icon(Icons.fiber_manual_record_rounded, size: 15),
                  label: const Text(
                    'INICIAR GRAVAÇÃO DA VIAGEM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomePage.laranja,
                    foregroundColor: HomePage.preto,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'O GPS será solicitado ao abrir a gravação',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    letterSpacing: .35,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Eyebrow('TELEMETRIA ACUMULADA'),
                  Text(
                    _loading ? 'SINCRONIZANDO' : 'SEU HISTÓRICO',
                    style: const TextStyle(
                      color: HomePage.laranja,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.52,
                children: [
                  _TelemetryTile(
                    label: 'DISTÂNCIA TOTAL',
                    value: '${_formatDistance(totalDistance)} km',
                    icon: Icons.alt_route_rounded,
                    accent: HomePage.laranja,
                  ),
                  _TelemetryTile(
                    label: 'TEMPO EM VIAGEM',
                    value: _formatDuration(totalSeconds),
                    icon: Icons.timer_outlined,
                    accent: HomePage.laranja,
                  ),
                  _TelemetryTile(
                    label: 'VIAGENS REGISTRADAS',
                    value: '${_trips.length}',
                    icon: Icons.flag_outlined,
                    accent: HomePage.verde,
                  ),
                  _TelemetryTile(
                    label: _premium ? 'CONSUMO MÉDIO' : 'MOTOS NA GARAGEM',
                    value: _premium
                        ? _averageConsumption()
                        : '${_bikes.length}',
                    icon: _premium
                        ? Icons.local_gas_station_outlined
                        : Icons.two_wheeler_rounded,
                    accent: HomePage.verde,
                    locked: !_premium,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _Eyebrow('ÚLTIMA VIAGEM REALIZADA'),
                  TextButton(
                    onPressed: _openRoutes,
                    style: TextButton.styleFrom(
                      foregroundColor: HomePage.laranja,
                    ),
                    child: const Text('VER TODAS'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (_error != null)
                _errorCard(context)
              else if (_loading)
                const _LoadingPanel()
              else if (lastTrip == null)
                _emptyRideCard(context)
              else
                _lastRideCard(context, lastTrip, lastBikeName),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Row(
    children: [
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'MOTO\n',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(
              text: 'RIDE',
              style: TextStyle(color: HomePage.laranja),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: 19,
          height: .95,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(width: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF292C32),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'HUD',
          style: TextStyle(
            color: HomePage.laranja,
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0D0F),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: HomePage.verde,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              _loading ? 'SYNC' : (_error == null ? 'READY' : 'OFFLINE'),
              style: const TextStyle(
                color: HomePage.verde,
                fontFamily: 'monospace',
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 9),
      const Icon(Icons.tune_rounded, color: Color(0xFFB4B8C0), size: 23),
    ],
  );

  Widget _connectionStrip() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1A1C20),
      border: Border.all(color: HomePage.borda),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      children: [
        Icon(
          _error == null ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: _error == null ? HomePage.verde : const Color(0xFFFF6B6B),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _loading
                ? 'SINCRONIZANDO COM SUA CONTA'
                : (_error == null
                      ? 'DADOS DA CONTA SINCRONIZADOS'
                      : 'FALHA AO SINCRONIZAR'),
            style: TextStyle(
              color: _error == null ? HomePage.verde : const Color(0xFFFF8A8A),
              fontFamily: 'monospace',
              fontSize: 10,
              letterSpacing: .6,
            ),
          ),
        ),
        const Text(
          'MOTO RIDE',
          style: TextStyle(
            color: Color(0xFF949AA3),
            fontFamily: 'monospace',
            fontSize: 9,
          ),
        ),
      ],
    ),
  );

  Widget _vehiclePanel(
    BuildContext context,
    Map<String, dynamic>? bike,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: HomePage.painel,
      border: Border.all(color: HomePage.borda),
      borderRadius: BorderRadius.circular(10),
    ),
    child: bike == null
        ? Row(
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                color: HomePage.laranja,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Eyebrow('GARAGEM'),
                    SizedBox(height: 5),
                    Text(
                      'Cadastre sua primeira moto',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_bikes.length} MOTO',
                style: const TextStyle(
                  color: HomePage.verde,
                  fontFamily: 'monospace',
                  fontSize: 9,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.two_wheeler_rounded,
                    color: HomePage.laranja,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(child: _Eyebrow('VEÍCULO CADASTRADO')),
                  Text(
                    bike['placa']?.toString() ?? 'GARAGEM',
                    style: const TextStyle(
                      color: HomePage.verde,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bike['modelo']?.toString() ?? 'Motocicleta',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                [
                  if (bike['cilindrada'] != null) '${bike['cilindrada']} cc',
                  if (bike['ano'] != null) bike['ano'].toString(),
                  if (bike['cor']?.toString().isNotEmpty == true)
                    bike['cor'].toString(),
                ].join('  ·  '),
                style: const TextStyle(
                  color: Color(0xFFB2B7C0),
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
              if (_premium && bike['consumo_km_l'] is num) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.local_gas_station_outlined,
                      color: HomePage.verde,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(bike['consumo_km_l'] as num).toStringAsFixed(1)} km/L',
                      style: const TextStyle(
                        color: HomePage.verde,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (bike['capacidade_tanque_litros'] is num)
                      Text(
                        'TANQUE ${(bike['capacidade_tanque_litros'] as num).toStringAsFixed(0)} L',
                        style: const TextStyle(
                          color: Color(0xFFB2B7C0),
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ] else if (bike['capacidade_tanque_litros'] is num) ...[
                const SizedBox(height: 10),
                Text(
                  'TANQUE ${(bike['capacidade_tanque_litros'] as num).toStringAsFixed(0)} L',
                  style: const TextStyle(
                    color: Color(0xFFB2B7C0),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
  );

  String _averageConsumption() {
    final values = _bikes
        .map((bike) => bike['consumo_km_l'])
        .whereType<num>()
        .toList();
    if (values.isEmpty) return '—';
    final average =
        values.fold<double>(0, (sum, value) => sum + value.toDouble()) /
        values.length;
    return '${average.toStringAsFixed(1)} km/L';
  }

  Widget _errorCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF28191A),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF5A292B)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFFF7777)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        IconButton(
          onPressed: _loadDashboard,
          icon: const Icon(Icons.refresh_rounded),
          color: Colors.white,
        ),
      ],
    ),
  );

  Widget _emptyRideCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: HomePage.painel,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: HomePage.borda),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF28201D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.route_outlined, color: HomePage.laranja),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nenhuma viagem registrada',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Sua primeira gravação aparece aqui.',
                style: TextStyle(color: Color(0xFF9BA0A8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _lastRideCard(
    BuildContext context,
    Map<String, dynamic> trip,
    String? bikeName,
  ) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: HomePage.painel,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: HomePage.borda),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.route_rounded, color: HomePage.laranja, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                trip['titulo']?.toString() ?? 'Viagem',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.north_east_rounded,
              color: Color(0xFF9BA0A8),
              size: 17,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          bikeName ?? 'Moto não informada',
          style: const TextStyle(
            color: Color(0xFFB2B7C0),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
        ),
        const Divider(height: 22, color: HomePage.borda),
        Row(
          children: [
            Expanded(
              child: _TripMetric(
                label: 'DISTÂNCIA',
                value: '${_formatDistance(trip['distancia_km'] as num?)} km',
              ),
            ),
            Expanded(
              child: _TripMetric(
                label: 'DURAÇÃO',
                value: _formatDuration(trip['duracao_segundos'] as num?),
              ),
            ),
            Expanded(
              child: _TripMetric(
                label: 'MÉDIA',
                value:
                    '${((trip['velocidade_media'] as num?) ?? 0).toStringAsFixed(0)} km/h',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFFCEB2A7),
      fontFamily: 'monospace',
      fontSize: 10,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _TelemetryTile extends StatelessWidget {
  const _TelemetryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.locked = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: HomePage.painel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: HomePage.borda),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFCEB2A7),
                  fontFamily: 'monospace',
                  fontSize: 9,
                  letterSpacing: .35,
                ),
              ),
            ),
            if (locked)
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF777D86),
                size: 12,
              ),
          ],
        ),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: accent == HomePage.verde ? accent : Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9BA0A8),
          fontFamily: 'monospace',
          fontSize: 9,
          letterSpacing: .5,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    ],
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Center(child: CircularProgressIndicator(color: HomePage.laranja)),
  );
}
