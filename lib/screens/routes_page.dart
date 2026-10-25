
import 'package:flutter/material.dart';

import '../services/strava_api.dart';
import 'active_ride_page.dart';
import 'home_page.dart';
import 'route_detail_page.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await StravaApi.listarViagens();

      if (mounted) {
        setState(() => _routes = data);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startRide() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ActiveRidePage(),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  String _fmtDate(dynamic value) {
    if (value == null) return 'Data não informada';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _duration(dynamic value) {
    final seconds = (value as num?)?.toInt() ?? 0;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) return '${hours}h ${minutes}min';

    return '$minutes min';
  }

  Future<void> _edit(Map<String, dynamic> route) async {
    final titleController = TextEditingController(
      text: route['titulo']?.toString() ?? '',
    );
    List<Map<String, dynamic>> bikes = [];
    String? selectedBikeId = route['motocicleta_id']?.toString();
    bool loadingBikes = true;
    bool saving = false;

    try {
      bikes = await StravaApi.listarMotos();
      loadingBikes = false;
    } catch (e) {
      loadingBikes = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            'Não foi possível carregar as motos: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          )),
        );
      }
    }

    final hasSelectedBike = bikes.any(
      (bike) => bike['id'].toString() == selectedBikeId,
    );
    if (!hasSelectedBike) selectedBikeId = '';

    if (!mounted) {
      titleController.dispose();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Editar viagem'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nome da viagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBikeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Motocicleta',
                      border: OutlineInputBorder(),
                    ),
                    hint: Text(
                      loadingBikes ? 'Carregando motos...' : 'Selecione uma moto',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Nenhuma motocicleta'),
                      ),
                      ...bikes.map((bike) => DropdownMenuItem<String>(
                        value: bike['id'].toString(),
                        child: Text(
                          '${bike['modelo'] ?? 'Moto'} - ${bike['cilindrada'] ?? '?'} cc',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: saving || loadingBikes
                        ? null
                        : (value) => setDialogState(
                              () => selectedBikeId = value,
                            ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: saving || loadingBikes
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Informe o nome da viagem.'),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          await StravaApi.editarViagem(
                            route['id'].toString(),
                            {
                              'titulo': title,
                              'motocicleta_id':
                                  selectedBikeId == null || selectedBikeId!.isEmpty
                                      ? null
                                      : selectedBikeId,
                            },
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      },
                icon: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Salvando...' : 'Salvar'),
              ),
            ],
          );
        },
      ),
    );

    titleController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viagem atualizada com sucesso!')),
      );
      await _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir viagem?'),
        content: Text(
          'Deseja excluir "${route['titulo']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await StravaApi.excluirViagem(route['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem excluída com sucesso!'),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    } else if (_routes.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.route,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma viagem salva ainda.',
                style: TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicie uma viagem e finalize para '
                'salvá-la no seu histórico.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startRide,
                icon: const Icon(Icons.play_arrow),
                label: const Text('INICIAR VIAGEM'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomePage.laranja,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _routes.length,
          itemBuilder: (context, index) {
            final item = _routes[index];

            final distance =
                (item['distancia_km'] as num?)
                        ?.toStringAsFixed(1) ??
                    '0.0';

            final avg =
                (item['velocidade_media'] as num?)
                        ?.toStringAsFixed(1) ??
                    '0.0';

            final max =
                (item['velocidade_maxima'] as num?)
                        ?.toStringAsFixed(1) ??
                    '0.0';

            final relatedBike = item['motocicletas'];

            final bikeName = relatedBike is Map
                ? relatedBike['modelo']?.toString()
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailPage(
                        routeName:
                            item['titulo']?.toString() ?? 'Viagem',
                        distance: '$distance km',
                        duration: _duration(
                          item['duracao_segundos'],
                        ),
                        avgSpeed: '$avg km/h',
                        maxSpeed: '$max km/h',
                        movingTime: _duration(
                          item['tempo_movimento_segundos'],
                        ),
                        stoppedTime: _duration(
                          item['tempo_parado_segundos'],
                        ),
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
                        children: [
                          Expanded(
                            child: Text(
                              item['titulo']?.toString() ??
                                  'Viagem',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Editar viagem',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(item),
                          ),
                          IconButton(
                            tooltip: 'Excluir viagem',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _delete(item),
                          ),
                        ],
                      ),
                      Text(
                        '${_fmtDate(item['data_inicio'] ?? item['criado_em'])}'
                        ' • ${bikeName ?? 'Moto não informada'}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '$distance km • '
                              '${_duration(item['duracao_segundos'])}',
                            ),
                          ),
                          Text(
                            '$avg km/h',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: HomePage.laranja,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minhas Rotas e Viagens',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar histórico',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startRide,
        backgroundColor: HomePage.laranja,
        foregroundColor: Colors.white,
        tooltip: 'Iniciar viagem',
        child: const Icon(Icons.play_arrow),
      ),
      body: body,
    );
  }
}
