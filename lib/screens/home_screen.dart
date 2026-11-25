import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/services/google_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _saindo = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LugaresController>().listarLugares();
    });
  }

  Future<void> _sair() async {
    setState(() => _saindo = true);
    try {
      await GoogleAuthService.sair();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível concluir a saída.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saindo = false);
    }
  }

  Future<void> _cadastrar() async {
    final mensagem = await Navigator.pushNamed(context, 'cadastro_lugar');
    if (mounted && mensagem is String) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final usuario = FirebaseAuth.instance.currentUser;
    final nome = usuario?.displayName?.split(' ').first ?? 'viajante';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia Turismo GB'),
        actions: [
          Consumer<ThemeController>(
            builder: (_, tema, child) => IconButton(
              tooltip: 'Alternar tema',
              onPressed: tema.alternarTema,
              icon: Icon(tema.iconeAtual),
            ),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: _saindo ? null : _sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.explore,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Olá, $nome!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu próximo passeio começa aqui.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${controller.lugares.length} lugares • ${controller.favoritos.length} favoritos',
                    textAlign: TextAlign.center,
                  ),
                  if (controller.carregando)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Ver lugares no mapa'),
                    onPressed: () => Navigator.pushNamed(context, 'mapa'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.view_list),
                    label: const Text('Explorar lugares'),
                    onPressed: () => Navigator.pushNamed(context, 'lugares'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.favorite),
                    label: const Text('Meus favoritos'),
                    onPressed: () => Navigator.pushNamed(context, 'favoritos'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Cadastrar lugar com foto'),
                    onPressed: _cadastrar,
                  ),
                  const SizedBox(height: 18),
                  if (controller.aviso.isNotEmpty || controller.erro.isNotEmpty)
                    Text(
                      controller.aviso.isNotEmpty
                          ? controller.aviso
                          : controller.erro,
                      textAlign: TextAlign.center,
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
