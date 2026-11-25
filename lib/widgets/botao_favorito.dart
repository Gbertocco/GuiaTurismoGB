import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';

class BotaoFavorito extends StatelessWidget {
  final LugaresModel lugar;
  const BotaoFavorito({super.key, required this.lugar});
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final favorito = controller.ehFavorito(lugar);
    return IconButton(
      tooltip: favorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
      icon: Icon(
        favorito ? Icons.favorite : Icons.favorite_border,
        color: favorito ? Colors.redAccent : null,
      ),
      onPressed: controller.alterandoFavorito(lugar)
          ? null
          : () async {
              final ok = await controller.alternarFavorito(lugar);
              if (!context.mounted || ok) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Não foi possível salvar o favorito. Tente novamente.',
                  ),
                ),
              );
            },
    );
  }
}
