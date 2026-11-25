import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/widgets/detalhes_lugar.dart';
import 'package:guia_turismo/widgets/mapa_lugares.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});
  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with WidgetsBindingObserver {
  final _mapa = GlobalKey<MapaLugaresState>();
  final _busca = TextEditingController();
  GpsController? _gps;
  String _categoria = '';
  bool _soFavoritos = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LugaresController>().listarLugares();
      _gps = context.read<GpsController>();
      _gps!.iniciar();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _gps?.iniciar(solicitarPermissao: false);
    } else {
      _gps?.parar();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gps?.parar();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _centralizar() async {
    final gps = context.read<GpsController>();
    await gps.atualizar();
    if (!mounted) return;
    if (gps.erro.isEmpty) _mapa.currentState?.centralizarUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final gps = context.watch<GpsController>();
    final categoria = controller.categorias.contains(_categoria)
        ? _categoria
        : '';
    final busca = _busca.text.trim().toLowerCase();
    final lugares = controller.lugares
        .where(
          (l) =>
              l.temCoordenadas &&
              (categoria.isEmpty || l.categoriaExibicao == categoria) &&
              (!_soFavoritos || controller.ehFavorito(l)) &&
              '${l.nome} ${l.categoria} ${l.descricao}'.toLowerCase().contains(
                busca,
              ),
        )
        .toList();
    final semCoordenadas = controller.lugares
        .where((l) => !l.temCoordenadas)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de lugares'),
        actions: [
          IconButton(
            tooltip: 'Ver lista',
            onPressed: () async {
              gps.parar();
              await Navigator.pushNamed(context, 'lugares');
              if (mounted) gps.iniciar(solicitarPermissao: false);
            },
            icon: const Icon(Icons.view_list),
          ),
          IconButton(
            tooltip: 'Atualizar lugares',
            onPressed: controller.carregando
                ? null
                : () => controller.listarLugares(forcar: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _busca,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar lugar',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: categoria,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Todas as categorias'),
                      ),
                      ...controller.categorias.map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoria = v ?? ''),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Favoritos'),
                  avatar: const Icon(Icons.favorite, size: 18),
                  selected: _soFavoritos,
                  onSelected: (v) => setState(() => _soFavoritos = v),
                ),
              ],
            ),
          ),
          if (controller.carregando) const LinearProgressIndicator(),
          if (controller.erro.isNotEmpty || controller.aviso.isNotEmpty)
            MaterialBanner(
              content: Text(
                controller.erro.isNotEmpty ? controller.erro : controller.aviso,
              ),
              actions: [
                TextButton(
                  onPressed: controller.carregando
                      ? null
                      : () => controller.listarLugares(forcar: true),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          if (gps.erro.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      gps.erro,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        gps.codigoErro == 'GPS_DESLIGADO' ||
                            gps.codigoErro == 'PERMISSAO_BLOQUEADA'
                        ? gps.abrirConfiguracoes
                        : _centralizar,
                    child: Text(
                      gps.codigoErro == 'GPS_DESLIGADO' ||
                              gps.codigoErro == 'PERMISSAO_BLOQUEADA'
                          ? 'Configurações'
                          : 'Tentar',
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                MapaLugares(
                  key: _mapa,
                  lugares: lugares,
                  posicao: gps.posicao,
                  onSelecionar: (l) => mostrarDetalhesLugar(context, l),
                ),
                if (lugares.isEmpty && !controller.carregando)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Nenhum lugar corresponde aos filtros.'),
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom: 38,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'enquadrar',
                        tooltip: 'Mostrar todos os lugares',
                        onPressed: () => _mapa.currentState?.enquadrar(),
                        child: const Icon(Icons.fit_screen),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'gps',
                        tooltip: 'Minha localização',
                        onPressed: gps.carregando ? null : _centralizar,
                        child: gps.carregando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 78,
                  bottom: 38,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        '${lugares.length} lugares no mapa'
                        '${semCoordenadas > 0 ? ' • $semCoordenadas sem coordenadas' : ''}'
                        '${gps.posicao != null ? '\nPonto azul: ${gps.erro.isEmpty ? 'você' : 'última posição'} • distância em linha reta' : '\nUse o GPS para ver sua posição e as distâncias'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
