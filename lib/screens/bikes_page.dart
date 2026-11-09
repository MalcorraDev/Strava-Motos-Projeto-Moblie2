import 'package:flutter/material.dart';
import '../services/strava_api.dart';
import 'home_page.dart';

class BikesPage extends StatefulWidget {
  const BikesPage({super.key});

  @override
  State<BikesPage> createState() => _BikesPageState();
}

class _BikesPageState extends State<BikesPage> {
  List<Map<String, dynamic>> _bikes = [];
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
      final rows = await StravaApi.listarMotos();

      if (mounted) {
        setState(() => _bikes = rows);
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

  Future<void> _openBikeForm({Map<String, dynamic>? bike}) async {
    final model = TextEditingController(
      text: bike?['modelo']?.toString() ?? '',
    );

    final cc = TextEditingController(
      text: bike?['cilindrada']?.toString() ?? '',
    );

    final consumption = TextEditingController(
      text: bike?['consumo_km_l']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    bool saving = false;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bike == null
                              ? 'Cadastrar Motocicleta'
                              : 'Editar Motocicleta',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: model,
                          decoration: const InputDecoration(
                            labelText: 'Modelo',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o modelo.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: cc,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cilindrada (cc)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final cilindrada = int.tryParse(value ?? '');

                            if (cilindrada == null || cilindrada <= 0) {
                              return 'Informe uma cilindrada válida.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: consumption,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Consumo (km/L, opcional)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }

                            final consumo = double.tryParse(
                              value.trim().replaceAll(',', '.'),
                            );

                            if (consumo == null || consumo <= 0) {
                              return 'Informe um consumo válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HomePage.laranja,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    setSheetState(() {
                                      saving = true;
                                    });

                                    try {
                                      final modelo = model.text.trim();

                                      final cilindrada = int.parse(
                                        cc.text.trim(),
                                      );

                                      final consumoTexto = consumption.text
                                          .trim()
                                          .replaceAll(',', '.');

                                      final double? consumo =
                                          consumoTexto.isEmpty
                                          ? null
                                          : double.parse(consumoTexto);

                                      if (bike == null) {
                                        await StravaApi.criarMoto(
                                          modelo: modelo,
                                          cilindrada: cilindrada,
                                          consumo: consumo,
                                        );
                                      } else {
                                        await StravaApi.editarMoto(
                                          bike['id'].toString(),
                                          {
                                            'modelo': modelo,
                                            'cilindrada': cilindrada,
                                            'consumo_km_l': consumo,
                                          },
                                        );
                                      }

                                      if (!sheetContext.mounted) {
                                        return;
                                      }

                                      Navigator.of(sheetContext).pop();

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              bike == null
                                                  ? 'Motocicleta cadastrada com sucesso!'
                                                  : 'Motocicleta atualizada com sucesso!',
                                            ),
                                          ),
                                        );

                                        await _load();
                                      }
                                    } catch (e) {
                                      if (!sheetContext.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      // O formulário pode ter sido fechado.
                                      // Nunca atualizar o estado depois disso.
                                      if (sheetContext.mounted) {
                                        setSheetState(() {
                                          saving = false;
                                        });
                                      }
                                    }
                                  },
                            child: Text(
                              saving
                                  ? 'SALVANDO...'
                                  : bike == null
                                  ? 'CADASTRAR'
                                  : 'SALVAR ALTERAÇÕES',
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      model.dispose();
      cc.dispose();
      consumption.dispose();
    }
  }

  Future<void> _delete(Map<String, dynamic> bike) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir motocicleta?'),
        content: Text('Deseja excluir ${bike['modelo']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      await StravaApi.excluirMoto(bike['id'].toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Motocicleta excluída com sucesso!')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha garagem'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HomePage.laranja,
        onPressed: () => _openBikeForm(),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar moto'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : _bikes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E9),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        size: 42,
                        color: HomePage.laranja,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Sua garagem começa aqui',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Cadastre sua moto para associá-la às viagens e acompanhar o consumo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF827B77), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _openBikeForm(),
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar primeira moto'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                itemCount: _bikes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sua garagem',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_bikes.length} ${_bikes.length == 1 ? 'motocicleta cadastrada' : 'motocicletas cadastradas'}',
                            style: const TextStyle(color: Color(0xFF827B77)),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: HomePage.preto,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.two_wheeler_rounded,
                                  color: HomePage.laranja,
                                  size: 25,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Mantenha seus modelos e dados de consumo organizados em um só lugar.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      height: 1.35,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final bike = _bikes[index - 1];

                  final cc = bike['cilindrada']?.toString() ?? '—';

                  final consumo = bike['consumo_km_l'] == null
                      ? 'Não informado'
                      : '${bike['consumo_km_l']} km/L';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: HomePage.preto,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.two_wheeler_rounded,
                              color: HomePage.laranja,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bike['modelo']?.toString() ?? 'Moto',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    _BikeTag(label: '$cc cc'),
                                    _BikeTag(label: consumo),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Opções da moto',
                            onSelected: (value) {
                              if (value == 'editar') _openBikeForm(bike: bike);
                              if (value == 'excluir') _delete(bike);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'excluir',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BikeTag extends StatelessWidget {
  const _BikeTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF8E3B20),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
