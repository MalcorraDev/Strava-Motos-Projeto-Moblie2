import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/strava_api.dart';
import '../services/app_preferences.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _activatingPremium = false;
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

  Future<void> _activatePremiumTest() async {
    if (_activatingPremium) return;
    setState(() => _activatingPremium = true);
    try {
      await StravaApi.ativarPremiumTeste();
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium de teste ativado por R\$ 0,00.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _activatingPremium = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;
    final metadata = authUser?.userMetadata ?? const <String, dynamic>{};
    final googleName = (metadata['full_name'] ?? metadata['name'])
        ?.toString()
        .trim();
    final storedName = _profile?['nome']?.toString().trim();
    final isPlaceholder =
        storedName == null ||
        storedName.isEmpty ||
        RegExp(
          r'^(usuario teste|usuário teste|nome não informado)$',
          caseSensitive: false,
        ).hasMatch(storedName);
    final name = isPlaceholder && googleName?.isNotEmpty == true
        ? googleName
        : storedName;
    final email = _profile?['email']?.toString().trim();
    final photoUrl =
        (_profile?['foto_url'] ?? metadata['avatar_url'] ?? metadata['picture'])
            ?.toString();
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
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF35302E)
                            : const Color(0xFFF0E8E4),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipOval(
                          child: photoUrl != null && photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _avatarFallback(),
                                )
                              : _avatarFallback(),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SEU PERFIL',
                                style: TextStyle(
                                  color: HomePage.laranja,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                name?.isNotEmpty == true
                                    ? name!
                                    : 'Nome não informado',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                email?.isNotEmpty == true
                                    ? email!
                                    : 'E-mail não informado',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF827B77),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1A1C20)
                          : HomePage.laranja,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF30343A)
                            : HomePage.laranja,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: HomePage.laranja,
                              size: 30,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                premium
                                    ? 'Moto Ride Premium'
                                    : 'Moto Ride Gratuito',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          premium
                              ? 'Sua conta possui acesso Premium.'
                              : 'Sua conta ainda não possui assinatura Premium.',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFB6BBC4)
                                : Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!premium) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _activatingPremium
                                  ? null
                                  : _activatePremiumTest,
                              icon: _activatingPremium
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 18,
                                    ),
                              label: Text(
                                _activatingPremium
                                    ? 'ATIVANDO...'
                                    : 'ATIVAR PREMIUM DE TESTE · R\$ 0,00',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HomePage.laranja,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Disponível somente para contas autorizadas na Vercel enquanto o modo de teste estiver ligado.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aparência',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: SwitchListTile.adaptive(
                      secondary: Icon(
                        AppPreferences.themeMode.value == ThemeMode.dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: HomePage.laranja,
                      ),
                      title: const Text('Modo escuro'),
                      subtitle: const Text(
                        'Salvar esta preferência neste dispositivo.',
                      ),
                      value: AppPreferences.themeMode.value == ThemeMode.dark,
                      activeThumbColor: HomePage.laranja,
                      onChanged: AppPreferences.setDarkMode,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Conta',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: HomePage.laranja,
                        ),
                      ),
                      title: const Text(
                        'Conta Google conectada',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        email?.isNotEmpty == true
                            ? email!
                            : 'E-mail não informado',
                      ),
                      trailing: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF42A75A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                      ),
                      title: const Text(
                        'Sair da conta',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Encerrar a sessão neste dispositivo.',
                      ),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Sair da conta?'),
                            content: const Text(
                              'Você precisará entrar novamente para acessar o aplicativo.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Sair'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await Supabase.instance.client.auth.signOut();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _avatarFallback() => Container(
    width: 68,
    height: 68,
    color: HomePage.preto,
    alignment: Alignment.center,
    child: const Icon(Icons.person, size: 38, color: Colors.white),
  );
}
