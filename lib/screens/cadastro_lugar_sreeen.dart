import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/localizacao_service.dart';
import 'package:guia_turismo/widgets/mapa_lugares.dart';
import 'package:provider/provider.dart';

class CadastroLugarScreen extends StatefulWidget {
  const CadastroLugarScreen({super.key});

  @override
  State<CadastroLugarScreen> createState() => _CadastroLugarScreenState();
}

class _CadastroLugarScreenState extends State<CadastroLugarScreen> {
  final form = GlobalKey<FormState>();
  final nome = TextEditingController();
  final descricao = TextEditingController();
  final latitude = TextEditingController();
  final longitude = TextEditingController();
  final endereco = TextEditingController();
  final localizacaoService = LocalizacaoService();
  bool buscando = false;
  String erroBusca = '';
  LugaresModel? localSelecionado;

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    latitude.dispose();
    longitude.dispose();
    endereco.dispose();
    localizacaoService.dispose();
    super.dispose();
  }

  double? converterNumero(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  String? validarCoordenada(String? texto, double limite) {
    final numero = converterNumero(texto ?? '');
    if (numero == null || !numero.isFinite) {
      return 'Informe um número válido.';
    }
    if (numero < -limite || numero > limite) {
      return 'Use um valor entre -${limite.toInt()} e ${limite.toInt()}.';
    }
    return null;
  }

  Future<void> buscarEndereco() async {
    if (buscando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      buscando = true;
      erroBusca = '';
    });

    try {
      final locais = await localizacaoService.buscarEndereco(endereco.text);
      if (!mounted) return;
      if (locais.isEmpty) {
        setState(
          () => erroBusca =
              'Endereço não encontrado. Tente incluir a cidade ou outro CEP.',
        );
        return;
      }

      final local = locais.length == 1
          ? locais.first
          : await showModalBottomSheet<LugaresModel>(
              context: context,
              showDragHandle: true,
              builder: (context) => SafeArea(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Selecione o endereço',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ...locais.map(
                      (local) => ListTile(
                        leading: const Icon(Icons.place),
                        title: Text(local.nome),
                        onTap: () => Navigator.pop(context, local),
                      ),
                    ),
                  ],
                ),
              ),
            );
      if (!mounted || local == null) return;
      setState(() {
        localSelecionado = local;
        latitude.text = local.latitude.toString();
        longitude.text = local.longitude.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => erroBusca = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => buscando = false);
    }
  }

  Future<void> salvar() async {
    if (buscando) return;
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = context.read<LugaresController>();
    final lugar = LugaresModel(
      nome: nome.text.trim(),
      descricao: descricao.text.trim(),
      latitude: converterNumero(latitude.text)!,
      longitude: converterNumero(longitude.text)!,
      // A API pede uma categoria, então deixei a 1 fixa.
      categoriaId: 1,
    );

    final cadastrou = await controller.cadastrarLugar(lugar);
    if (!mounted) return;

    if (cadastrou) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    return PopScope(
      canPop: !controller.salvando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastrar lugar')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nome,
                  enabled: !controller.salvando,
                  decoration: const InputDecoration(labelText: 'Nome do lugar'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe o nome do lugar.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descricao,
                  enabled: !controller.salvando,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a descrição do lugar.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: endereco,
                  enabled: !controller.salvando && !buscando,
                  decoration: const InputDecoration(
                    labelText: 'Endereço ou CEP',
                    hintText: 'Rua, número e cidade ou 01001-000',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: controller.salvando || buscando
                      ? null
                      : buscarEndereco,
                  icon: const Icon(Icons.map),
                  label: Text(buscando ? 'Buscando...' : 'Buscar no mapa'),
                ),
                if (erroBusca.isNotEmpty)
                  Text(
                    erroBusca,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (localSelecionado != null) ...[
                  const SizedBox(height: 12),
                  Text(localSelecionado!.nome),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 220,
                    child: MapaLugares(
                      key: ValueKey(
                        '${localSelecionado!.latitude},${localSelecionado!.longitude}',
                      ),
                      lugares: [localSelecionado!],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confira o local. Você também pode ajustar as coordenadas abaixo.',
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: latitude,
                  enabled: !controller.salvando && !buscando,
                  onChanged: (_) => setState(() => localSelecionado = null),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (valor) => validarCoordenada(valor, 90),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: longitude,
                  enabled: !controller.salvando && !buscando,
                  onChanged: (_) => setState(() => localSelecionado = null),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (valor) => validarCoordenada(valor, 180),
                ),
                const SizedBox(height: 20),
                if (controller.erroCadastro.isNotEmpty)
                  Text(
                    controller.erroCadastro,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ElevatedButton(
                  onPressed: controller.salvando || buscando ? null : salvar,
                  child: Text(
                    controller.salvando ? 'Salvando...' : 'Salvar lugar',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
