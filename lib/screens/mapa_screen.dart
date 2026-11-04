import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/widgets/mapa_lugares.dart';
import 'package:provider/provider.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LugaresController>().listarLugares();
    });
  }

  void mostrarLugar(LugaresModel lugar) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lugar.nome, style: Theme.of(context).textTheme.titleLarge),
              if (lugar.categoria.isNotEmpty) Text(lugar.categoria),
              const SizedBox(height: 12),
              Text(lugar.descricao),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final lugares = controller.lugares
        .where(
          (lugar) =>
              lugar.latitude.isFinite &&
              lugar.longitude.isFinite &&
              lugar.latitude >= -90 &&
              lugar.latitude <= 90 &&
              lugar.longitude >= -180 &&
              lugar.longitude <= 180,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de lugares'),
        actions: [
          IconButton(
            tooltip: 'Atualizar lugares',
            onPressed: controller.carregando ? null : controller.listarLugares,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: controller.carregando
          ? const Center(child: CircularProgressIndicator())
          : controller.erro.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(controller.erro, textAlign: TextAlign.center),
                    ElevatedButton(
                      onPressed: controller.listarLugares,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                MapaLugares(lugares: lugares, onSelecionar: mostrarLugar),
                if (lugares.isEmpty)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Nenhum lugar com localização encontrado.'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
