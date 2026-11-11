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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: HomePage.laranja,
        onPressed: () => _openBikeForm(),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'ADICIONAR MOTO',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: HomePage.laranja,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'MOTO ',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: 'RIDE',
                            style: TextStyle(
                              color: HomePage.laranja,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    tooltip: 'Atualizar garagem',
                    icon: const Icon(Icons.sync_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _GarageEyebrow('GARAGEM DO PILOTO'),
              const SizedBox(height: 5),
              Text(
                'Suas motocicletas',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Fichas técnicas e dados da sua garagem.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HomePage.painel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HomePage.borda),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: HomePage.laranja.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: HomePage.laranja,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GarageEyebrow('VEÍCULOS CADASTRADOS'),
                          const SizedBox(height: 3),
                          Text(
                            _loading
                                ? 'SINCRONIZANDO'
                                : '${_bikes.length} ${_bikes.length == 1 ? 'MOTOCICLETA' : 'MOTOCICLETAS'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_premium)
                      const _GarageStatus(
                        label: 'PREMIUM',
                        color: HomePage.verde,
                      )
                    else
                      const _GarageStatus(
                        label: 'FREE',
                        color: HomePage.laranja,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _GarageEyebrow('FROTA'),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _errorView()
              else if (_bikes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: HomePage.painel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HomePage.borda),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.two_wheeler_rounded,
                        color: HomePage.laranja,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sua garagem começa aqui',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cadastre uma moto para associá-la às viagens.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _openBikeForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('CADASTRAR MOTO'),
                      ),
                    ],
                  ),
                )
              else
                ..._bikes.map((bike) => _garageBikeCard(context, bike)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: HomePage.painel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HomePage.borda),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: HomePage.verde,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _premium
                            ? 'Consumo médio é calculado com os dados registrados nas viagens.'
                            : 'Consumo médio e estimativa de combustível são recursos Premium.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _garageBikeCard(BuildContext context, Map<String, dynamic> bike) {
    final cc = bike['cilindrada']?.toString() ?? '—';
    final plate = bike['placa']?.toString().trim();
    final year = bike['ano']?.toString();
    final color = bike['cor']?.toString().trim();
    final tank = bike['capacidade_tanque_litros'];
    final consumption = bike['consumo_km_l'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: HomePage.painel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HomePage.borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: HomePage.laranja,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HomePage.laranja.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: HomePage.laranja,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GarageEyebrow('MOTO CADASTRADA'),
                          const SizedBox(height: 3),
                          Text(
                            bike['modelo']?.toString() ?? 'Motocicleta',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
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
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BikeTag(label: '$cc cc'),
                    if (plate != null && plate.isNotEmpty)
                      _BikeTag(label: plate.toUpperCase()),
                    if (year != null && year.isNotEmpty) _BikeTag(label: year),
                    if (color != null && color.isNotEmpty)
                      _BikeTag(label: color),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _BikeFact(
                        label: 'TANQUE',
                        value: tank == null ? '—' : '${tank.toString()} L',
                        icon: Icons.local_gas_station_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BikeFact(
                        label: _premium ? 'CONSUMO MÉDIO' : 'CONSUMO',
                        value: _premium && consumption != null
                            ? '${consumption.toString()} km/L'
                            : 'PREMIUM',
                        icon: _premium
                            ? Icons.speed_rounded
                            : Icons.lock_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _GarageEyebrow extends StatelessWidget {
  const _GarageEyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: HomePage.laranja,
      fontFamily: 'monospace',
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

class _GarageStatus extends StatelessWidget {
  const _GarageStatus({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontFamily: 'monospace',
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}

class _BikeFact extends StatelessWidget {
  const _BikeFact({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: HomePage.preto,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: HomePage.laranja, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF999BA1),
                  fontFamily: 'monospace',
                  fontSize: 8,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == 'PREMIUM' ? HomePage.laranja : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
