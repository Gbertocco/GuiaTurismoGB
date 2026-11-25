import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';
import 'package:guia_turismo/widgets/botao_favorito.dart';
import 'package:guia_turismo/widgets/foto_lugar.dart';

Future<void> mostrarDetalhesLugar(BuildContext context, LugaresModel lugar) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DetalhesLugar(lugar: lugar),
    );

class DetalhesLugar extends StatefulWidget {
  final LugaresModel lugar;
  const DetalhesLugar({super.key, required this.lugar});
  @override
  State<DetalhesLugar> createState() => _DetalhesLugarState();
}

class _DetalhesLugarState extends State<DetalhesLugar> {
  final _service = DispositivoService();
  bool _ocupado = false;
  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir o aplicativo. Tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lugar = widget.lugar;
    final gps = context.watch<GpsController>();
    final distancia = gps.posicao?.distanciaAte(lugar);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      minChildSize: .35,
      maxChildSize: .95,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FotoLugar(lugar: lugar),
            if (!lugar.temFoto)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Este lugar ainda não possui foto.'),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lugar.nome,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                BotaoFavorito(lugar: lugar),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(lugar.categoriaExibicao)),
                if (lugar.apenasNesteDispositivo)
                  const Chip(label: Text('Salvo neste aparelho')),
              ],
            ),
            if (distancia != null)
              Text('${formatarDistancia(distancia)} de você, em linha reta'),
            if (lugar.endereco.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(lugar.endereco),
              ),
            const SizedBox(height: 12),
            Text(
              lugar.descricao.isEmpty
                  ? 'Sem descrição disponível.'
                  : lugar.descricao,
            ),
            if (!lugar.temCoordenadas)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Localização não informada para este lugar.'),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _ocupado || !lugar.temCoordenadas
                  ? null
                  : () => _executar(() => _service.comoChegar(lugar)),
              icon: const Icon(Icons.directions),
              label: const Text('Como chegar'),
            ),
            OutlinedButton.icon(
              onPressed: _ocupado
                  ? null
                  : () => _executar(() => _service.compartilhar(lugar)),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar lugar'),
            ),
          ],
        ),
      ),
    );
  }
}
