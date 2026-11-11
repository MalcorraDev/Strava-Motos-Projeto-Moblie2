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
  bool _premium = false;
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
      var premium = false;
      try {
        premium = (await StravaApi.perfil())['premium'] == true;
      } catch (_) {
        // Keep the free experience if the profile cannot be refreshed.
      }

      if (mounted) {
        setState(() {
          _bikes = rows;
          _premium = premium;
        });
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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BikeFormSheet(
        bike: bike,
        premium: _premium,
        onSave: (values) async {
          if (bike == null) {
            await StravaApi.criarMoto(
              modelo: values['modelo'] as String,
              cilindrada: values['cilindrada'] as int,
              consumo: _premium ? values['consumo_km_l'] as double? : null,
              placa: values['placa'] as String?,
              ano: values['ano'] as int?,
              cor: values['cor'] as String?,
              capacidadeTanque: values['capacidade_tanque_litros'] as double?,
            );
          } else {
            final update = Map<String, dynamic>.from(values);
            if (!_premium) update.remove('consumo_km_l');
            await StravaApi.editarMoto(bike['id'].toString(), update);
          }
        },
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                                    if (bike['placa']?.toString().isNotEmpty ==
                                        true)
                                      _BikeTag(label: bike['placa'].toString()),
                                    if (bike['ano'] != null)
                                      _BikeTag(label: bike['ano'].toString()),
                                    if (_premium &&
                                        bike['consumo_km_l'] != null)
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

class _BikeFormSheet extends StatefulWidget {
  const _BikeFormSheet({
    required this.bike,
    required this.premium,
    required this.onSave,
  });

  final Map<String, dynamic>? bike;
  final bool premium;
  final Future<void> Function(Map<String, dynamic> values) onSave;

  @override
  State<_BikeFormSheet> createState() => _BikeFormSheetState();
}

class _BikeFormSheetState extends State<_BikeFormSheet> {
  late final TextEditingController _modelController;
  late final TextEditingController _ccController;
  late final TextEditingController _consumptionController;
  late final TextEditingController _plateController;
  late final TextEditingController _yearController;
  late final TextEditingController _colorController;
  late final TextEditingController _tankController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(
      text: widget.bike?['modelo']?.toString() ?? '',
    );
    _ccController = TextEditingController(
      text: widget.bike?['cilindrada']?.toString() ?? '',
    );
    _consumptionController = TextEditingController(
      text: widget.bike?['consumo_km_l']?.toString() ?? '',
    );
    _plateController = TextEditingController(
      text: widget.bike?['placa']?.toString() ?? '',
    );
    _yearController = TextEditingController(
      text: widget.bike?['ano']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: widget.bike?['cor']?.toString() ?? '',
    );
    _tankController = TextEditingController(
      text: widget.bike?['capacidade_tanque_litros']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _modelController.dispose();
    _ccController.dispose();
    _consumptionController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _tankController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final consumptionText = _consumptionController.text.trim().replaceAll(
        ',',
        '.',
      );
      final plate = _plateController.text.trim().toUpperCase().replaceAll(
        RegExp(r'[^A-Z0-9]'),
        '',
      );
      final year = _yearController.text.trim();
      final tankText = _tankController.text.trim().replaceAll(',', '.');
      await widget.onSave({
        'modelo': _modelController.text.trim(),
        'cilindrada': int.parse(_ccController.text.trim()),
        if (widget.premium)
          'consumo_km_l': consumptionText.isEmpty
              ? null
              : double.parse(consumptionText),
        'placa': plate.isEmpty ? null : plate,
        'ano': year.isEmpty ? null : int.parse(year),
        'cor': _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        'capacidade_tanque_litros': tankText.isEmpty
            ? null
            : double.parse(tankText),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bike == null
                    ? 'Cadastrar Motocicleta'
                    : 'Editar Motocicleta',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _modelController,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o modelo.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ccController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Cilindrada (cc)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final cc = int.tryParse(value ?? '');
                  return cc == null || cc <= 0 || cc > 9999
                      ? 'Informe uma cilindrada válida.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 7,
                decoration: const InputDecoration(
                  labelText: 'Placa (opcional)',
                  hintText: 'ABC1D23',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final plate = (value ?? '').toUpperCase().replaceAll(
                    RegExp(r'[^A-Z0-9]'),
                    '',
                  );
                  if (plate.isEmpty) return null;
                  return RegExp(
                        r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$',
                      ).hasMatch(plate)
                      ? null
                      : 'Informe placa no padrão ABC1234 ou ABC1D23.';
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText: 'Ano',
                        hintText: '2024',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final year = int.tryParse(value.trim());
                        return year == null ||
                                year < 1900 ||
                                year > DateTime.now().year + 1
                            ? 'Ano inválido.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Cor',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length < 2
                          ? 'Cor inválida.'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tankController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Capacidade do tanque (L)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final capacity = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );
                  return capacity == null || capacity < 1 || capacity > 100
                      ? 'Informe de 1 a 100 litros.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              if (widget.premium)
                TextFormField(
                  controller: _consumptionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Consumo (km/L, opcional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final consumption = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );
                    return consumption == null ||
                            consumption <= 0 ||
                            consumption > 100
                        ? 'Informe um consumo válido.'
                        : null;
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF26292E)
                        : const Color(0xFFFFF0E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, color: HomePage.laranja),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Consumo médio km/L é um recurso Premium.'),
                      ),
                    ],
                  ),
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
                  onPressed: _saving ? null : _submit,
                  child: Text(
                    _saving
                        ? 'SALVANDO...'
                        : widget.bike == null
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF26292E)
            : const Color(0xFFFFF0E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFF8A5B)
              : const Color(0xFF8E3B20),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
