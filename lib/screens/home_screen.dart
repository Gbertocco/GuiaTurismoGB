import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Guia de Turismo'),
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
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Cadastrar lugar'),
        onPressed: () async {
          final salvo = await Navigator.pushNamed(context, 'cadastro_lugar');
          if (!context.mounted || salvo != true) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lugar cadastrado com sucesso!')),
          );
        },
      ),
    ),
  );
}
