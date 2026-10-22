import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
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

  @override
  void dispose() {
    nome.dispose();
    descricao.dispose();
    latitude.dispose();
    longitude.dispose();
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

  Future<void> salvar() async {
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
                  controller: latitude,
                  enabled: !controller.salvando,
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
                  enabled: !controller.salvando,
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
                  onPressed: controller.salvando ? null : salvar,
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
