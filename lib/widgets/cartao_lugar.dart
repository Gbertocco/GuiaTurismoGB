import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';
import 'package:guia_turismo/widgets/botao_favorito.dart';
import 'package:guia_turismo/widgets/detalhes_lugar.dart';
import 'package:guia_turismo/widgets/foto_lugar.dart';

class CartaoLugar extends StatelessWidget {
  final LugaresModel lugar;
  const CartaoLugar({super.key, required this.lugar});
  @override
  Widget build(BuildContext context) {
    final distancia = context.watch<GpsController>().posicao?.distanciaAte(
      lugar,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => mostrarDetalhesLugar(context, lugar),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FotoLugar(lugar: lugar, altura: 88, largura: 88),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lugar.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(lugar.categoriaExibicao),
                    if (distancia != null) Text(formatarDistancia(distancia)),
                    if (!lugar.temCoordenadas) const Text('Sem localização'),
                  ],
                ),
              ),
              BotaoFavorito(lugar: lugar),
            ],
          ),
        ),
      ),
    );
  }
}
