import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';
import 'package:guia_turismo/widgets/foto_lugar.dart';

class MapaLugares extends StatefulWidget {
  final List<LugaresModel> lugares;
  final PosicaoUsuario? posicao;
  final ValueChanged<LugaresModel>? onSelecionar;
  final ValueChanged<LatLng>? onToque;
  final TileProvider? tileProvider;
  const MapaLugares({
    super.key,
    required this.lugares,
    this.posicao,
    this.onSelecionar,
    this.onToque,
    this.tileProvider,
  });
  @override
  State<MapaLugares> createState() => MapaLugaresState();
}

class MapaLugaresState extends State<MapaLugares> {
  final _mapa = MapController();
  bool _pronto = false;
  bool _erroTiles = false;
  List<LatLng> get _pontos => widget.lugares
      .where((l) => l.temCoordenadas)
      .map((l) => LatLng(l.latitude.toDouble(), l.longitude.toDouble()))
      .toList();
  @override
  void didUpdateWidget(covariant MapaLugares oldWidget) {
    super.didUpdateWidget(oldWidget);
    final antigas = oldWidget.lugares.map((l) => l.chave).join('|');
    final novas = widget.lugares.map((l) => l.chave).join('|');
    if (antigas != novas && widget.lugares.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) enquadrar();
      });
    }
  }

  void centralizarUsuario() {
    final posicao = widget.posicao;
    if (_pronto && posicao != null) {
      _mapa.move(LatLng(posicao.latitude, posicao.longitude), 16);
    }
  }

  void enquadrar() {
    if (!_pronto) return;
    final pontos = _pontos;
    if (pontos.isEmpty) {
      centralizarUsuario();
      return;
    }
    if (pontos.length == 1) {
      _mapa.move(pontos.first, 15);
      return;
    }
    _mapa.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pontos),
        padding: const EdgeInsets.all(65),
        maxZoom: 16,
      ),
    );
  }

  Future<void> _creditos() async {
    try {
      await DispositivoService.canal.invokeMethod<void>('abrirUrl', {
        'url': 'https://www.openstreetmap.org/copyright',
      });
    } on PlatformException {
      /* O crédito continua visível mesmo sem navegador. */
    } on MissingPluginException {
      /* Os recursos nativos são destinados ao Android. */
    }
  }

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pontos = _pontos;
    final posicao = widget.posicao;
    final centro =
        pontos.firstOrNull ??
        (posicao == null
            ? const LatLng(-14.235, -51.9253)
            : LatLng(posicao.latitude, posicao.longitude));
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCenter: centro,
            initialZoom: pontos.isEmpty && posicao == null ? 4 : 15,
            maxZoom: 19,
            onMapReady: () {
              _pronto = true;
              enquadrar();
            },
            onTap: (_, ponto) => widget.onToque?.call(ponto),
          ),
          children: [
            TileLayer(
              tileProvider: widget.tileProvider,
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.guia_turismo',
              errorTileCallback: (_, error, stack) {
                if (_erroTiles || !mounted) return;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_erroTiles) setState(() => _erroTiles = true);
                });
              },
            ),
            if (posicao != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(posicao.latitude, posicao.longitude),
                    radius: posicao.precisao.clamp(1, 500).toDouble(),
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: .12),
                    borderColor: Colors.blue.withValues(alpha: .35),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                ...widget.lugares
                    .where((l) => l.temCoordenadas)
                    .map(
                      (lugar) => Marker(
                        point: LatLng(
                          lugar.latitude.toDouble(),
                          lugar.longitude.toDouble(),
                        ),
                        width: 56,
                        height: 66,
                        alignment: Alignment.topCenter,
                        child: Semantics(
                          button: true,
                          label: 'Ver ${lugar.nome}',
                          child: GestureDetector(
                            onTap: () => widget.onSelecionar?.call(lugar),
                            child: Tooltip(
                              message: lugar.nome,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                    child: FotoLugar(
                                      lugar: lugar,
                                      altura: 42,
                                      largura: 42,
                                      raio: 24,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                if (posicao != null)
                  Marker(
                    point: LatLng(posicao.latitude, posicao.longitude),
                    width: 26,
                    height: 26,
                    child: Tooltip(
                      message: 'Sua localização atual',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black26),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SimpleAttributionWidget(
              source: const Text('OpenStreetMap contributors'),
              onTap: _creditos,
            ),
          ],
        ),
        if (_erroTiles)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Algumas partes do mapa não carregaram. Verifique a internet.',
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _erroTiles = false),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
