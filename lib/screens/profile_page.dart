import 'package:flutter/material.dart';
import '../services/strava_api.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await StravaApi.perfil();
      if (!mounted) return;
      setState(() => _profile = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['nome']?.toString().trim();
    final email = _profile?['email']?.toString().trim();
    final photoUrl = _profile?['foto_url']?.toString();
    final premium = _profile?['premium'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            onPressed: _loadProfile,
            tooltip: 'Atualizar perfil',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadProfile, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: HomePage.preto,
                              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              name?.isNotEmpty == true ? name! : 'Nome não informado',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              email?.isNotEmpty == true ? email! : 'E-mail não informado',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [HomePage.laranja, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    premium ? 'Moto Ride Premium' : 'Moto Ride Gratuito',
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              premium
                                  ? 'Sua conta possui acesso Premium.'
                                  : 'Sua conta ainda não possui assinatura Premium.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'A contratação de assinatura não está integrada nesta versão.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.account_circle_outlined),
                        title: const Text('Conta cadastrada'),
                        subtitle: Text(email?.isNotEmpty == true ? email! : 'E-mail não informado'),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                      const Divider(),
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('Sessão'),
                        subtitle: Text('A autenticação e o encerramento de sessão não estão integrados nesta versão.'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
