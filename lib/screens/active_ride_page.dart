import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

import '../services/strava_api.dart';
import 'home_page.dart';

class ActiveRidePage extends StatefulWidget {
  const ActiveRidePage({super.key});

  @override
  State<ActiveRidePage> createState() => _ActiveRidePageState();
}

class _ActiveRidePageState extends State<ActiveRidePage> {
  final Stopwatch _stopwatch = Stopwatch();
  final MapController _mapController = MapController();
  Timer? _timer;
  StreamSubscription<Position>? _locationSubscription;

  final TextEditingController _titleController = TextEditingController();

  List<Map<String, dynamic>> _bikes = [];
  String? _selectedBikeId;

  bool _paused = false;
  bool _starting = false;
  bool _saving = false;
  bool _loadingBikes = true;
  bool _rideStarted = false;
  bool _mapReady = false;
  bool _backgroundLocationEnabled = false;
  bool _premium = false;
  String? _gpsError;
  double _distanceMeters = 0;
  int _movingMilliseconds = 0;
  double _currentSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  final List<LatLng> _track = [];
  final List<Map<String, dynamic>> _trackPayload = [];
  Position? _lastPosition;
  Position? _currentPosition;

  DateTime? _startTime;

  int get _seconds => _stopwatch.elapsed.inSeconds;

  LocationSettings get _locationSettings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: _backgroundLocationEnabled
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Viagem Moto Ride em andamento',
                notificationText: 'Registrando sua localização e percurso.',
                notificationChannelName: 'Rastreamento de viagem',
                setOngoing: true,
              )
            : null,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadBikes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareLocation(requestBackground: false).then((ready) async {
        if (!ready || !mounted) return;
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 20),
            ),
          );
          if (mounted) _onPosition(position);
        } catch (error) {
          if (mounted) {
            setState(() => _gpsError = 'Aguardando posição GPS: $error');
          }
        }
      });
      StravaApi.perfil()
          .then((profile) {
            if (mounted) setState(() => _premium = profile['premium'] == true);
          })
          .catchError((_) {});
    });
  }

  Future<void> _loadBikes() async {
    try {
      final bikes = await StravaApi.listarMotos();

      if (!mounted) return;

      setState(() {
        _bikes = bikes;
        _loadingBikes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingBikes = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível carregar as motos: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<bool> _prepareLocation({bool requestBackground = true}) async {
    try {
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return false;
      if (!serviceEnabled) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ative a localização'),
            content: const Text(
              'O GPS do aparelho está desligado. Ative a localização para registrar esta viagem.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Abrir configurações'),
              ),
            ],
          ),
        );
        if (!mounted) return false;
        if (openSettings == true) {
          await Geolocator.openLocationSettings();
          if (!mounted) return false;
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
        }
        if (!serviceEnabled) {
          setState(() => _gpsError = 'Ative o GPS do aparelho para iniciar.');
          return false;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (!mounted) return false;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        // Ao entrar nesta tela, solicita a permissão de localização em primeiro plano.
        permission = await Geolocator.requestPermission();
        if (!mounted) return false;
      }
      if (permission == LocationPermission.deniedForever) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permissão de localização bloqueada'),
            content: const Text(
              'O Android não exibirá novamente a solicitação. Libere a localização nas configurações do aplicativo para gravar viagens.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Abrir configurações'),
              ),
            ],
          ),
        );
        if (!mounted) return false;
        if (openSettings == true) await Geolocator.openAppSettings();
        if (mounted) {
          setState(
            () => _gpsError =
                'Permita a localização nas configurações e toque em Iniciar viagem novamente.',
          );
        }
        return false;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        setState(
          () => _gpsError =
              'Permita o acesso à localização para gravar a viagem.',
        );
        return false;
      }

      _backgroundLocationEnabled = false;
      if (requestBackground &&
          !kIsWeb &&
          defaultTargetPlatform == TargetPlatform.android &&
          permission != LocationPermission.always) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rastreamento em segundo plano'),
            content: const Text(
              'Para continuar gravando com a tela bloqueada, o Android precisa da permissão “Permitir o tempo todo”. Você também pode continuar com o app aberto.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Só com o app aberto'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Abrir configurações'),
              ),
            ],
          ),
        );
        if (!mounted) return false;
        if (openSettings == true) {
          await Geolocator.openAppSettings();
          if (!mounted) return false;
          permission = await Geolocator.checkPermission();
          if (!mounted) return false;
          if (permission != LocationPermission.always) {
            setState(
              () => _gpsError =
                  'Ative “Permitir o tempo todo” nas permissões de localização para gravar com a tela bloqueada.',
            );
            return false;
          }
        }
        _backgroundLocationEnabled = permission == LocationPermission.always;
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _gpsError = 'Não foi possível preparar o GPS: $error');
      }
      return false;
    }
  }

  Future<void> _startRide() async {
    if (_starting || _loadingBikes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aguarde o carregamento das motocicletas.'),
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome da viagem.')),
      );
      return;
    }

    if (_selectedBikeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma motocicleta para iniciar.'),
        ),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      if (!await _prepareLocation() || !mounted) return;

      setState(() {
        _rideStarted = true;
        _paused = false;
        _startTime = DateTime.now();
        _gpsError = null;
      });

      await _subscribeLocation(_locationSettings);
      if (!mounted) return;

      _stopwatch.start();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _rideStarted && !_paused) {
          setState(() {});
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _rideStarted = false;
          _gpsError = 'Não foi possível iniciar o rastreamento GPS: $error';
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _subscribeLocation(LocationSettings settings) async {
    final previousSubscription = _locationSubscription;
    _locationSubscription = null;
    await previousSubscription?.cancel();
    if (!mounted || !_rideStarted || _paused) return;

    _locationSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _onPosition,
          onError: (Object error) {
            if (mounted) {
              setState(() => _gpsError = 'Falha ao ler o GPS: $error');
            }
          },
        );
  }

  void _onPosition(Position position) {
    if (!mounted || (_rideStarted && _paused)) return;
    if (position.latitude.isNaN ||
        position.longitude.isNaN ||
        position.accuracy < 0) {
      return;
    }
    _currentPosition = position;
    final point = LatLng(position.latitude, position.longitude);
    if (_mapReady) _mapController.move(point, 16);
    if (!_rideStarted) {
      setState(
        () => _gpsError = position.accuracy > 50
            ? 'Localização encontrada, mas o sinal ainda está impreciso.'
            : null,
      );
      return;
    }
    if (position.accuracy <= 0) return;
    if (position.accuracy > 50) {
      if (_gpsError !=
          'Sinal GPS fraco. Vá para uma área aberta para obter melhor precisão.') {
        setState(
          () => _gpsError =
              'Sinal GPS fraco. Vá para uma área aberta para obter melhor precisão.',
        );
      }
      return;
    }

    final previous = _lastPosition;
    var speed = 0.0;
    if (previous != null) {
      final meters = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );
      final seconds =
          position.timestamp.difference(previous.timestamp).inMilliseconds /
          1000;
      if (seconds <= 0 || meters / seconds * 3.6 > 220) return;
      _distanceMeters += meters;
      if (seconds > 0) speed = meters / seconds * 3.6;
      if (speed >= 3) {
        _movingMilliseconds += position.timestamp
            .difference(previous.timestamp)
            .inMilliseconds
            .clamp(0, 10000)
            .toInt();
      }
    }

    _lastPosition = position;
    _track.add(point);
    final previousSaved = _trackPayload.isEmpty ? null : _trackPayload.last;
    final shouldSavePoint =
        previousSaved == null ||
        Geolocator.distanceBetween(
              previousSaved['latitude'] as double,
              previousSaved['longitude'] as double,
              position.latitude,
              position.longitude,
            ) >=
            20;
    if (shouldSavePoint && _trackPayload.length < 20000) {
      _trackPayload.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toUtc().toIso8601String(),
        'accuracy_m': position.accuracy,
        'speed_kmh': double.parse(speed.toStringAsFixed(1)),
      });
    }
    _currentSpeedKmh = speed;
    if (speed > _maxSpeedKmh) _maxSpeedKmh = speed;
    if (_mapReady) _mapController.move(point, 16);
    setState(() => _gpsError = null);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePause() async {
    if (!_rideStarted || _saving) return;

    if (_paused) {
      _stopwatch.start();
      _lastPosition = null;
      setState(() => _paused = false);
      await _subscribeLocation(_locationSettings);
    } else {
      _stopwatch.stop();
      _currentSpeedKmh = 0;
      setState(() => _paused = true);
      final subscription = _locationSubscription;
      _locationSubscription = null;
      await subscription?.cancel();
    }
  }

  Future<void> _finishRide() async {
    if (_saving || !_rideStarted || _startTime == null) return;

    Map<String, dynamic>? selectedBike;
    for (final bike in _bikes) {
      if (bike['id'] == _selectedBikeId) selectedBike = bike;
    }
    final consumption = (selectedBike?['consumo_km_l'] as num?)?.toDouble();
    final estimatedFuelLiters =
        _premium && consumption != null && consumption > 0
        ? (_distanceMeters / 1000) / consumption
        : null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar viagem?'),
        content: Text(
          'O tempo registrado foi de ${_formatDuration(_seconds)}. '
          '${!_premium
              ? 'Estimativa de combustível é exclusiva do Premium.'
              : estimatedFuelLiters == null
              ? 'Cadastre o consumo km/L da moto para ver a estimativa de combustível.'
              : 'Consumo estimado: ${estimatedFuelLiters.toStringAsFixed(2)} L.'} '
          'Deseja salvar esta viagem?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Finalizar e salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    _stopwatch.stop();
    _timer?.cancel();
    await _locationSubscription?.cancel();

    try {
      final duration = _seconds;
      final endTime = DateTime.now();
      final distanceKm = _distanceMeters / 1000;
      final averageSpeed = duration > 0 ? distanceKm / (duration / 3600) : 0.0;
      final movingSeconds = (_movingMilliseconds / 1000)
          .round()
          .clamp(0, duration)
          .toInt();
      final stoppedSeconds = duration - movingSeconds;

      final body = <String, dynamic>{
        'titulo': _titleController.text.trim().isEmpty
            ? 'Minha viagem'
            : _titleController.text.trim(),
        'data_inicio': _startTime!.toIso8601String(),
        'data_fim': endTime.toIso8601String(),
        'distancia_km': double.parse(distanceKm.toStringAsFixed(3)),
        'duracao_segundos': duration,
        'tempo_movimento_segundos': movingSeconds,
        'tempo_parado_segundos': stoppedSeconds,
        'velocidade_media': double.parse(averageSpeed.toStringAsFixed(2)),
        'velocidade_maxima': double.parse(_maxSpeedKmh.toStringAsFixed(2)),
        if (estimatedFuelLiters != null)
          'combustivel_estimado_litros': double.parse(
            estimatedFuelLiters.toStringAsFixed(3),
          ),
        'pontos_gps': _trackPayload,
        'motocicleta_id': _selectedBikeId,
      };

      await StravaApi.criarViagem(body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viagem salva no Supabase com sucesso!')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      // A gravação falhou: permite tentar novamente sem perder
      // o estado de pausa da viagem.
      if (!_paused) {
        _stopwatch.start();
        _lastPosition = null;
        await _subscribeLocation(_locationSettings);
      }
      if (!mounted) return;

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _rideStarted && !_paused) {
          setState(() {});
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    _stopwatch.stop();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.preto,
      appBar: AppBar(
        backgroundColor: HomePage.preto,
        foregroundColor: Colors.white,
        title: Text(_rideStarted ? 'Viagem em andamento' : 'Configurar viagem'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition == null
                          ? const LatLng(0, 0)
                          : LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                      initialZoom: _currentPosition == null ? 2 : 16,
                      onMapReady: () {
                        _mapReady = true;
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          );
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.com.stravamotos.app',
                      ),
                      if (_track.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _track,
                              strokeWidth: 5,
                              color: HomePage.laranja,
                            ),
                          ],
                        ),
                      if (_currentPosition != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              radius: _currentPosition!.accuracy
                                  .clamp(8.0, 70.0)
                                  .toDouble(),
                              useRadiusInMeter: true,
                              color: const Color(0x331D75F0),
                              borderColor: const Color(0xFF1D75F0),
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 34,
                              height: 34,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D75F0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('© OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),
                  if (_currentPosition == null)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A1C20,
                          ).withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _gpsError ?? 'Aguardando localização do aparelho…',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (_gpsError != null)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(10),
                        color: const Color(0xFF1A1C20),
                        child: Text(
                          _gpsError!,
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    enabled: !_rideStarted && !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Nome da viagem',
                      hintText: 'Ex.: Passeio até a Serra',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBikeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Motocicleta *',
                      border: OutlineInputBorder(),
                    ),
                    hint: Text(
                      _loadingBikes
                          ? 'Carregando motos...'
                          : 'Selecione uma moto',
                    ),
                    items: _bikes.map((bike) {
                      return DropdownMenuItem<String>(
                        value: bike['id'].toString(),
                        child: Text(
                          '${bike['modelo']} - '
                          '${bike['cilindrada']} cc',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (_saving || _rideStarted || _loadingBikes)
                        ? null
                        : (value) {
                            setState(() {
                              _selectedBikeId = value;
                            });
                          },
                  ),
                  if (!_rideStarted) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentPosition == null
                          ? 'Permita a localização para centralizar o mapa e iniciar a viagem.'
                          : 'GPS localizado • precisão aproximada de ${_currentPosition!.accuracy.toStringAsFixed(0)} m',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(
                        _rideStarted ? _formatDuration(_seconds) : '--:--:--',
                        'DURAÇÃO',
                      ),
                      _stat(
                        '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                        'DISTÂNCIA',
                      ),
                      _stat(
                        '${_currentSpeedKmh.toStringAsFixed(1)} km/h',
                        'VELOCIDADE',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_rideStarted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving || _loadingBikes || _starting
                            ? null
                            : _startRide,
                        icon: _starting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(
                          _starting ? 'PREPARANDO GPS...' : 'INICIAR VIAGEM',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HomePage.laranja,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _togglePause,
                            icon: Icon(
                              _paused ? Icons.play_arrow : Icons.pause,
                            ),
                            label: Text(_paused ? 'RETOMAR' : 'PAUSAR'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _finishRide,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.stop),
                            label: Text(_saving ? 'SALVANDO...' : 'FINALIZAR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: HomePage.preto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: HomePage.laranja,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
