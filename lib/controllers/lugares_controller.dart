import 'package:flutter/foundation.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/armazenamento_service.dart';
import 'package:guia_turismo/services/fotos_service.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';

class LugaresController extends ChangeNotifier {
  final String usuarioId;
  final LugaresServices _service;
  final ArmazenamentoService _armazenamento;
  final FotosService _fotos;
  bool carregando = false,
      salvando = false,
      _inicializado = false,
      _descartado = false;
  String erro = '', aviso = '', erroCadastro = '', mensagemCadastro = '';
  List<LugaresModel> _api = [], _meus = [];
  Set<String> _favoritos = {};
  Future<void>? _cargaLocal;
  bool _falhaMeus = false, _falhaFavoritos = false;
  final Set<String> _alterandoFavoritos = {};
  String get _chaveMeus => 'meus_lugares_v2_$usuarioId';
  LugaresController({
    required this.usuarioId,
    LugaresServices? service,
    ArmazenamentoService? armazenamento,
    FotosService? fotos,
  }) : _service = service ?? LugaresServices(),
       _armazenamento = armazenamento ?? ArmazenamentoService(),
       _fotos = fotos ?? FotosService();
  List<LugaresModel> get lugares {
    final todos = {for (final lugar in _api) lugar.chave: lugar};
    for (final lugar in _meus) {
      todos[lugar.chave] = lugar;
    }
    return List.unmodifiable(todos.values);
  }

  List<LugaresModel> get favoritos => lugares.where(ehFavorito).toList();
  bool ehFavorito(LugaresModel lugar) => _favoritos.contains(lugar.chave);
  bool alterandoFavorito(LugaresModel lugar) => _alterandoFavoritos.isNotEmpty;
  List<String> get categorias =>
      (lugares.map((l) => l.categoriaExibicao).toSet().toList()..sort());
  List<({int id, String nome})> get categoriasCadastro {
    final itens = <int, String>{};
    for (final lugar in lugares) {
      if (lugar.categoriaId != null && lugar.categoria.isNotEmpty) {
        itens[lugar.categoriaId!] = lugar.categoria;
      }
    }
    if (itens.isEmpty) itens[1] = 'Geral';
    return itens.entries.map((e) => (id: e.key, nome: e.value)).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  Future<void> _carregarLocal() => _cargaLocal ??= _lerLocal();
  Future<void> _lerLocal() async {
    try {
      _meus = await _armazenamento.lerLugares(_chaveMeus);
    } catch (_) {
      _falhaMeus = true;
      aviso = 'Não foi possível recuperar os cadastros deste aparelho.';
    }
    try {
      _favoritos = await _armazenamento.lerFavoritos(usuarioId);
    } catch (_) {
      _falhaFavoritos = true;
      aviso = 'Não foi possível recuperar os favoritos.';
    }
    try {
      _api = await _armazenamento.lerLugares('lugares_api_cache_v2');
    } catch (_) {
      /* A API pode reconstruir o cache. */
    }
  }

  Future<void> listarLugares({bool forcar = false}) async {
    if (carregando || (_inicializado && !forcar)) return;
    carregando = true;
    erro = '';
    aviso = '';
    _avisar();
    try {
      await _carregarLocal();
      _avisar();
      try {
        _api = await _service.buscarLugares();
        try {
          await _armazenamento.salvarLugares('lugares_api_cache_v2', _api);
        } catch (_) {
          aviso =
              'Os lugares foram carregados, mas o cache não pôde ser atualizado.';
        }
      } catch (e) {
        if (lugares.isEmpty) {
          erro = e.toString();
        } else {
          aviso =
              'API indisponível. Exibindo os lugares salvos neste aparelho.';
        }
      }
      _inicializado = true;
    } finally {
      carregando = false;
      _avisar();
    }
  }

  Future<bool> alternarFavorito(LugaresModel lugar) async {
    if (_alterandoFavoritos.isNotEmpty) return false;
    await _carregarLocal();
    if (_falhaFavoritos || _descartado || _alterandoFavoritos.isNotEmpty) {
      return false;
    }
    _alterandoFavoritos.add(lugar.chave);
    final eraFavorito = ehFavorito(lugar);
    if (eraFavorito) {
      _favoritos.remove(lugar.chave);
    } else {
      _favoritos.add(lugar.chave);
    }
    _avisar();
    try {
      await _armazenamento.salvarFavoritos(usuarioId, _favoritos);
      return true;
    } catch (_) {
      if (eraFavorito) {
        _favoritos.add(lugar.chave);
      } else {
        _favoritos.remove(lugar.chave);
      }
      return false;
    } finally {
      _alterandoFavoritos.remove(lugar.chave);
      _avisar();
    }
  }

  Future<bool> cadastrarLugar(
    LugaresModel dados, {
    String? fotoTemporaria,
  }) async {
    if (salvando) return false;
    salvando = true;
    erroCadastro = '';
    mensagemCadastro = '';
    _avisar();
    try {
      await _carregarLocal();
      if (_falhaMeus) {
        throw Exception(
          'Não foi possível recuperar seus cadastros anteriores. Reinicie o app antes de salvar.',
        );
      }
      if (!dados.temCoordenadas) {
        throw Exception('Informe uma localização válida.');
      }
      if (fotoTemporaria == null || fotoTemporaria.isEmpty) {
        throw Exception('Adicione uma foto do lugar.');
      }
      final foto = await _fotos.guardar(fotoTemporaria, usuarioId);
      final novo = dados.copyWith(
        id: -DateTime.now().microsecondsSinceEpoch,
        fotoLocal: foto,
        apenasNesteDispositivo: true,
      );
      _meus = [..._meus, novo];
      try {
        await _armazenamento.salvarLugares(_chaveMeus, _meus);
      } catch (_) {
        _meus.removeLast();
        rethrow;
      }
      _avisar();
      const configurado = String.fromEnvironment('API_TOKEN');
      String token = configurado;
      if (token.isEmpty) {
        try {
          token = await SessionService().pegarToken() ?? '';
        } catch (_) {
          /* A sessão Google continua independente da API da disciplina. */
        }
      }
      mensagemCadastro = 'Lugar com foto salvo neste aparelho.';
      if (token.isNotEmpty && dados.categoriaId != null) {
        try {
          final publicado = await _service.cadastrarLugar(novo, token);
          final atualizados = _meus
              .map((l) => l.chave == novo.chave ? publicado : l)
              .toList();
          await _armazenamento.salvarLugares(_chaveMeus, atualizados);
          _meus = atualizados;
          mensagemCadastro =
              'Lugar publicado na API. A foto fica salva neste aparelho.';
        } catch (e) {
          debugPrint('Publicação na API não confirmada: $e');
          mensagemCadastro =
              'Lugar com foto salvo neste aparelho. A publicação na API não foi confirmada.';
        }
      }
      erro = '';
      return true;
    } catch (e) {
      erroCadastro = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      salvando = false;
      _avisar();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _service.dispose();
    super.dispose();
  }
}
