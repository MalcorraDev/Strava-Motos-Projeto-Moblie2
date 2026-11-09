import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'com.example.stravamotos://login-callback/',
      );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _friendlyError(error.message));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Não foi possível iniciar o login. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('provider is not enabled') ||
        normalized.contains('unsupported provider')) {
      return 'O login com Google ainda não está habilitado no Supabase.';
    }
    return 'O login não pôde ser concluído. Verifique a configuração do Google e tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5A1F),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      size: 62,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'STRAVA MOTOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sua jornada começa aqui.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata_rounded, size: 30),
                      label: Text(
                        _loading ? 'Conectando...' : 'Entrar com Google',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Ao continuar, você acessará sua conta Strava Motos com segurança.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
