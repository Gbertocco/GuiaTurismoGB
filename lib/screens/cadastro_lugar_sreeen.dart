import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/fotos_service.dart';
import 'package:guia_turismo/services/localizacao_service.dart';
import 'package:guia_turismo/widgets/foto_lugar.dart';
import 'package:guia_turismo/widgets/mapa_lugares.dart';

class CadastroLugarScreen extends StatefulWidget {
  const CadastroLugarScreen({super.key});
  @override
  State<CadastroLugarScreen> createState() => _CadastroLugarScreenState();
}

class _CadastroLugarScreenState extends State<CadastroLugarScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _endereco = TextEditingController();
  final _outraCategoria = TextEditingController();
  final _localizacao = LocalizacaoService();
  final _fotos = FotosService();
  final _mapa = GlobalKey<MapaLugaresState>();
  String? _foto;
  int? _categoriaId;
  String _categoriaNome = 'Outros';
  bool _buscando = false, _selecionandoFoto = false;
  String _erroBusca = '', _erroFoto = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LugaresController>().listarLugares();
      _recuperarFoto();
    });
  }

  Future<void> _recuperarFoto() async {
    try {
      final foto = await _fotos.recuperarFoto();
      if (mounted && foto != null) setState(() => _foto = foto.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erroFoto =
              'Não foi possível recuperar a foto anterior. Selecione novamente.',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final campo in [
      _nome,
      _descricao,
      _latitude,
      _longitude,
      _endereco,
      _outraCategoria,
    ]) {
      campo.dispose();
    }
    _localizacao.dispose();
    super.dispose();
  }

  double? _numero(String valor) =>
      double.tryParse(valor.trim().replaceAll(',', '.'));
  String? _validarCoordenada(String? texto, double limite) {
    final numero = _numero(texto ?? '');
    if (numero == null || !numero.isFinite) return 'Informe um número válido.';
    if (numero.abs() > limite) {
      return 'Use um valor entre -${limite.toInt()} e ${limite.toInt()}.';
    }
    return null;
  }

  LugaresModel? get _previa {
    final lat = _numero(_latitude.text), lng = _numero(_longitude.text);
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return null;
    }
    return LugaresModel(
      nome: _nome.text.trim().isEmpty ? 'Local selecionado' : _nome.text.trim(),
      latitude: lat,
      longitude: lng,
      fotoLocal: _foto ?? '',
    );
  }

  void _selecionarLocal(num latitude, num longitude) => setState(() {
    _latitude.text = latitude.toStringAsFixed(6);
    _longitude.text = longitude.toStringAsFixed(6);
    _erroBusca = '';
  });
  Future<void> _escolherFoto(ImageSource origem) async {
    if (_selecionandoFoto) return;
    setState(() {
      _selecionandoFoto = true;
      _erroFoto = '';
    });
    try {
      final foto = await _fotos.selecionar(origem);
      if (mounted && foto != null) setState(() => _foto = foto.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _erroFoto =
              'Não foi possível abrir a câmera ou galeria. Verifique as permissões do aparelho.',
        );
      }
    } finally {
      if (mounted) setState(() => _selecionandoFoto = false);
    }
  }

  Future<void> _usarGps() async {
    final gps = context.read<GpsController>();
    await gps.atualizar();
    if (!mounted) return;
    if (gps.erro.isNotEmpty) {
      setState(() => _erroBusca = gps.erro);
      return;
    }
    final posicao = gps.posicao;
    if (posicao != null) {
      _selecionarLocal(posicao.latitude, posicao.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapa.currentState?.enquadrar();
      });
    }
  }

  Future<void> _buscarEndereco() async {
    if (_buscando) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _erroBusca = '';
    });
    try {
      final locais = await _localizacao.buscarEndereco(_endereco.text);
      if (!mounted) return;
      if (locais.isEmpty) {
        setState(
          () => _erroBusca =
              'Endereço não encontrado. Inclua a cidade ou tente outro CEP.',
        );
        return;
      }
      final local = locais.length == 1
          ? locais.first
          : await showModalBottomSheet<LugaresModel>(
              context: context,
              showDragHandle: true,
              useSafeArea: true,
              builder: (context) => ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text('Selecione o endereço')),
                  ...locais.map(
                    (l) => ListTile(
                      leading: const Icon(Icons.place),
                      title: Text(l.nome),
                      onTap: () => Navigator.pop(context, l),
                    ),
                  ),
                ],
              ),
            );
      if (!mounted || local == null) return;
      _selecionarLocal(local.latitude, local.longitude);
      _endereco.text = local.nome;
    } catch (e) {
      if (mounted) {
        setState(
          () => _erroBusca = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  Future<void> _salvar() async {
    final valido = _form.currentState!.validate();
    if (_foto == null) {
      setState(() => _erroFoto = 'Adicione uma foto do lugar.');
    }
    if (!valido || _foto == null) return;
    FocusScope.of(context).unfocus();
    final controller = context.read<LugaresController>();
    final categoria = controller.categoriasCadastro
        .where((c) => c.id == _categoriaId)
        .firstOrNull;
    final lugar = LugaresModel(
      nome: _nome.text.trim(),
      descricao: _descricao.text.trim(),
      latitude: _numero(_latitude.text)!,
      longitude: _numero(_longitude.text)!,
      endereco: _endereco.text.trim(),
      categoriaId: _categoriaId == 0 ? null : _categoriaId,
      categoria: _categoriaId == 0
          ? _outraCategoria.text.trim()
          : categoria?.nome ?? _categoriaNome,
    );
    final ok = await controller.cadastrarLugar(lugar, fotoTemporaria: _foto);
    if (mounted && ok) Navigator.pop(context, controller.mensagemCadastro);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LugaresController>();
    final gps = context.watch<GpsController>();
    final categorias = controller.categoriasCadastro.toList();
    if (_categoriaId != null &&
        _categoriaId != 0 &&
        !categorias.any((c) => c.id == _categoriaId)) {
      categorias.add((id: _categoriaId!, nome: _categoriaNome));
    }
    final ocupado =
        controller.salvando || _buscando || _selecionandoFoto || gps.carregando;
    final previa = _previa;
    return PopScope(
      canPop: !controller.salvando,
      child: Scaffold(
        appBar: AppBar(title: const Text('Cadastrar lugar com foto')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Foto do lugar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FotoLugar(
                  lugar: LugaresModel(
                    nome: 'Novo lugar',
                    latitude: 0,
                    longitude: 0,
                    fotoLocal: _foto ?? '',
                  ),
                  largura: double.infinity,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _escolherFoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Câmera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: ocupado
                            ? null
                            : () => _escolherFoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
                if (_erroFoto.isNotEmpty)
                  Text(
                    _erroFoto,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nome,
                  enabled: !ocupado,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Nome do lugar'),
                  validator: (v) => v == null || v.trim().length < 3
                      ? 'Informe um nome com pelo menos 3 caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    ...categorias.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.nome)),
                    ),
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('Outra categoria'),
                    ),
                  ],
                  onChanged: ocupado
                      ? null
                      : (v) => setState(() {
                          _categoriaId = v;
                          _categoriaNome =
                              categorias
                                  .where((c) => c.id == v)
                                  .firstOrNull
                                  ?.nome ??
                              'Outros';
                        }),
                  validator: (v) =>
                      v == null ? 'Selecione uma categoria.' : null,
                ),
                if (_categoriaId == 0)
                  TextFormField(
                    controller: _outraCategoria,
                    enabled: !ocupado,
                    maxLength: 60,
                    decoration: const InputDecoration(
                      labelText: 'Nome da categoria',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe a categoria.'
                        : null,
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricao,
                  enabled: !ocupado,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (v) => v == null || v.trim().length < 5
                      ? 'Descreva o lugar com pelo menos 5 caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Localização',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                OutlinedButton.icon(
                  onPressed: ocupado ? null : _usarGps,
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    gps.carregando
                        ? 'Obtendo GPS...'
                        : 'Usar minha localização atual',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endereco,
                  enabled: !ocupado,
                  decoration: const InputDecoration(
                    labelText: 'Endereço ou CEP (opcional)',
                    hintText: 'Rua, número e cidade ou 01001-000',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                TextButton.icon(
                  onPressed: ocupado ? null : _buscarEndereco,
                  icon: const Icon(Icons.search),
                  label: Text(
                    _buscando ? 'Buscando...' : 'Buscar endereço no mapa',
                  ),
                ),
                if (_erroBusca.isNotEmpty)
                  Text(
                    _erroBusca,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (gps.codigoErro == 'PERMISSAO_BLOQUEADA' ||
                    gps.codigoErro == 'GPS_DESLIGADO')
                  TextButton(
                    onPressed: gps.abrirConfiguracoes,
                    child: const Text('Abrir configurações de localização'),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: IgnorePointer(
                    ignoring: ocupado,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: MapaLugares(
                        key: _mapa,
                        lugares: previa == null ? [] : [previa],
                        posicao: gps.posicao,
                        onToque: (ponto) =>
                            _selecionarLocal(ponto.latitude, ponto.longitude),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Toque no mapa para marcar o lugar ou informe as coordenadas abaixo.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _latitude,
                  enabled: !ocupado,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (v) => _validarCoordenada(v, 90),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _longitude,
                  enabled: !ocupado,
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (v) => _validarCoordenada(v, 180),
                ),
                const SizedBox(height: 20),
                if (controller.erroCadastro.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      controller.erroCadastro,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: ocupado ? null : _salvar,
                  icon: const Icon(Icons.save),
                  label: Text(
                    controller.salvando
                        ? 'Salvando...'
                        : 'Salvar lugar com foto',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fotos e cadastros locais permanecem neste aparelho, vinculados à sua conta.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
