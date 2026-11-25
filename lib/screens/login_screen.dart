import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:guia_turismo/services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _entrando = false;
  Future<void> _entrar() async {
    setState(() => _entrando = true);
    try {
      await GoogleAuthService.entrar();
    } on GoogleSignInException catch (erro) {
      if (erro.code != GoogleSignInExceptionCode.canceled) _erro(erro);
    } catch (erro) {
      _erro(erro);
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  void _erro(Object erro) {
    debugPrint('Erro no login Google: $erro');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível entrar. Verifique a internet e tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Guia Turismo GB')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore,
              size: 88,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Descubra seu próximo passeio',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Entre para cadastrar lugares e guardar seus favoritos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _entrando ? null : _entrar,
              icon: _entrando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_entrando ? 'Entrando...' : 'Entrar com Google'),
            ),
          ],
        ),
      ),
    ),
  );
}
