import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:guia_turismo/models/lugares_model.dart';
import 'package:latlong2/latlong.dart';

class MapaLugares extends StatelessWidget {
  final List<LugaresModel> lugares;
  final ValueChanged<LugaresModel>? onSelecionar;

  const MapaLugares({super.key, required this.lugares, this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    final pontos = lugares
        .map((lugar) => LatLng(lugar.latitude, lugar.longitude))
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: pontos.isEmpty
            ? const LatLng(-14.235, -51.9253)
            : pontos.first,
        initialZoom: pontos.isEmpty ? 4 : 15,
        initialCameraFit: pontos.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(pontos),
                padding: const EdgeInsets.all(50),
                maxZoom: 15,
              )
            : null,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.com.gbertocco.guiaturismo',
        ),
        MarkerLayer(
          markers: lugares
              .map(
                (lugar) => Marker(
                  point: LatLng(lugar.latitude, lugar.longitude),
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: Tooltip(
                    message: lugar.nome,
                    child: GestureDetector(
                      onTap: onSelecionar == null
                          ? null
                          : () => onSelecionar!(lugar),
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }
}
