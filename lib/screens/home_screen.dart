import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Guia Turismo GB'),
      actions: [
        Consumer<ThemeController>(
          builder: (context, tema, child) => IconButton(
            onPressed: tema.alternarTema,
            icon: Icon(tema.iconeAtual),
          ),
        ),
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Seu próximo passeio começa aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Ver lugares no mapa'),
              onPressed: () => Navigator.pushNamed(context, 'mapa'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Cadastrar lugar'),
              onPressed: () async {
                final salvo = await Navigator.pushNamed(
                  context,
                  'cadastro_lugar',
                );
                if (!context.mounted || salvo != true) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lugar cadastrado com sucesso!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
