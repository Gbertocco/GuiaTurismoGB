import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/widgets/cartao_lugar.dart';

class LugaresScreen extends StatefulWidget {
  final bool somenteFavoritos;
  const LugaresScreen({super.key, this.somenteFavoritos = false});
  @override
  State<LugaresScreen> createState() => _LugaresScreenState();
}

class _LugaresScreenState extends State<LugaresScreen> {
  final _busca = TextEditingController();
  String _categoria = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LugaresController>().listarLugares();
    });
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final gps = context.watch<GpsController>();
    final categoria = controller.categorias.contains(_categoria)
        ? _categoria
        : '';
    final busca = _busca.text.trim().toLowerCase();
    final lista =
        (widget.somenteFavoritos ? controller.favoritos : controller.lugares)
            .where(
              (l) =>
                  (categoria.isEmpty || l.categoriaExibicao == categoria) &&
                  '${l.nome} ${l.categoria} ${l.descricao}'
                      .toLowerCase()
                      .contains(busca),
            )
            .toList();
    if (gps.posicao != null) {
      lista.sort(
        (a, b) => (gps.posicao!.distanciaAte(a) ?? double.infinity).compareTo(
          gps.posicao!.distanciaAte(b) ?? double.infinity,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.somenteFavoritos ? 'Meus favoritos' : 'Lugares para visitar',
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar minha localização',
            onPressed: gps.carregando
                ? null
                : () async {
                    await gps.atualizar();
                    if (context.mounted && gps.erro.isNotEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(gps.erro)));
                    }
                  },
            icon: const Icon(Icons.my_location),
          ),
          IconButton(
            tooltip: 'Atualizar',
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
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busca,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Buscar lugar',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: categoria,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Todas as categorias'),
                ),
                ...controller.categorias.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => setState(() => _categoria = v ?? ''),
            ),
          ),
          if (controller.carregando) const LinearProgressIndicator(),
          if (controller.aviso.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(controller.aviso),
            ),
          Expanded(
            child: lista.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.somenteFavoritos
                                ? Icons.favorite_border
                                : Icons.travel_explore,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.erro.isNotEmpty
                                ? controller.erro
                                : widget.somenteFavoritos
                                ? 'Seus lugares favoritos aparecerão aqui. Toque no coração de um lugar.'
                                : 'Nenhum lugar encontrado. Você pode cadastrar um novo lugar.',
                            textAlign: TextAlign.center,
                          ),
                          if (controller.erro.isNotEmpty)
                            TextButton(
                              onPressed: () =>
                                  controller.listarLugares(forcar: true),
                              child: const Text('Tentar novamente'),
                            ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => controller.listarLugares(forcar: true),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 90),
                      itemCount: lista.length,
                      itemBuilder: (_, index) => CartaoLugar(
                        key: ValueKey(lista[index].chave),
                        lugar: lista[index],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Cadastrar lugar',
        onPressed: () async {
          final mensagem = await Navigator.pushNamed(context, 'cadastro_lugar');
          if (context.mounted && mensagem is String) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(mensagem)));
          }
        },
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }
}
