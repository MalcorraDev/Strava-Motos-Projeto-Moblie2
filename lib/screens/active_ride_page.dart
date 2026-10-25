
import 'dart:async';

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
  Timer? _timer;

  final TextEditingController _titleController =
      TextEditingController();

  List<Map<String, dynamic>> _bikes = [];
  String? _selectedBikeId;

  bool _paused = false;
  bool _saving = false;
  bool _loadingBikes = true;
  bool _rideStarted = false;

  DateTime? _startTime;

  int get _seconds => _stopwatch.elapsed.inSeconds;

  @override
  void initState() {
    super.initState();

    _loadBikes();
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


  void _startRide() {
    if (_loadingBikes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde o carregamento das motocicletas.')),
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
        const SnackBar(content: Text('Selecione uma motocicleta para iniciar.')),
      );
      return;
    }

    setState(() {
      _rideStarted = true;
      _paused = false;
      _startTime = DateTime.now();
    });

    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _rideStarted && !_paused) {
        setState(() {});
      }
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    if (!_rideStarted || _saving) return;

    if (_paused) {
      _stopwatch.start();
    } else {
      _stopwatch.stop();
    }

    setState(() => _paused = !_paused);
  }

  Future<void> _finishRide() async {
    if (_saving || !_rideStarted || _startTime == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Finalizar viagem?'),
        content: Text(
          'O tempo registrado foi de '
          '${_formatDuration(_seconds)}. '
          'Deseja salvar esta viagem?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Finalizar e salvar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);

    _stopwatch.stop();
    _timer?.cancel();

    try {
      final duration = _seconds;
      final endTime = DateTime.now();

      final body = <String, dynamic>{
        'titulo': _titleController.text.trim().isEmpty
            ? 'Minha viagem'
            : _titleController.text.trim(),
        'data_inicio': _startTime!.toIso8601String(),
        'data_fim': endTime.toIso8601String(),
        'distancia_km': 0.0,
        'duracao_segundos': duration,
        'tempo_movimento_segundos': duration,
        'tempo_parado_segundos': 0,
        'velocidade_media': 0.0,
        'velocidade_maxima': 0.0,
        'motocicleta_id': _selectedBikeId,
      };

      await StravaApi.criarViagem(body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Viagem salva no Supabase com sucesso!',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      // A gravação falhou: permite tentar novamente sem perder
      // o estado de pausa da viagem.
      if (!_paused) _stopwatch.start();

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
              child: Container(
                width: double.infinity,
                color: const Color(0xFF242424),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !_rideStarted
                          ? Icons.route_outlined
                          : _paused
                              ? Icons.pause_circle_outline
                              : Icons.navigation,
                      size: 76,
                      color: HomePage.laranja,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      !_rideStarted
                          ? 'Configure sua viagem'
                          : _paused
                              ? 'Viagem pausada'
                              : 'Viagem em andamento',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      child: Text(
                        !_rideStarted
                            ? 'Informe um nome e selecione a motocicleta. '
                                'O cronômetro começa somente ao tocar em INICIAR VIAGEM.'
                            : 'O tempo está sendo registrado. '
                                'O rastreamento GPS real ainda não está implementado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: [
                      _stat(
                        _rideStarted ? _formatDuration(_seconds) : '--:--:--',
                        'DURAÇÃO',
                      ),
                      _stat('0,0 km', 'DISTÂNCIA'),
                      _stat('0,0 km/h', 'VELOCIDADE'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!_rideStarted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving || _loadingBikes ? null : _startRide,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('INICIAR VIAGEM'),
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
                            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
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
