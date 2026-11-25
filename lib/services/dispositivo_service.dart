import 'package:flutter/services.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';

// Ponte com os recursos nativos do Android, sem rastreamento em segundo plano.
class DispositivoService {
  static const canal = MethodChannel('com.example.guia_turismo/dispositivo');
  Future<PosicaoUsuario> obterPosicao({bool solicitarPermissao = true}) async {
    final dados = await canal
        .invokeMapMethod<String, dynamic>('obterPosicao', {
          'solicitarPermissao': solicitarPermissao,
        })
        .timeout(const Duration(seconds: 30));
    if (dados == null) {
      throw const FormatException('O GPS não retornou uma posição.');
    }
    return PosicaoUsuario.fromMap(dados);
  }

  Future<String> diretorioDocumentos() async {
    final caminho = await canal.invokeMethod<String>('diretorioDocumentos');
    if (caminho == null || caminho.isEmpty) {
      throw const FormatException(
        'Não foi possível salvar a foto neste aparelho.',
      );
    }
    return caminho;
  }

  Future<void> abrirConfiguracoesGps() =>
      canal.invokeMethod<void>('configuracoesGps');
  Future<void> abrirConfiguracoesApp() =>
      canal.invokeMethod<void>('configuracoesApp');
  static Uri linkMapa(LugaresModel lugar) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': '${lugar.latitude},${lugar.longitude}'},
  );
  Future<void> comoChegar(LugaresModel lugar) async {
    if (!lugar.temCoordenadas) {
      throw const FormatException('Este lugar não tem localização válida.');
    }
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${lugar.latitude},${lugar.longitude}',
      'travelmode': 'driving',
    });
    await canal.invokeMethod<void>('abrirUrl', {'url': url.toString()});
  }

  Future<void> compartilhar(LugaresModel lugar) =>
      canal.invokeMethod<void>('compartilhar', {
        'titulo': lugar.nome,
        'texto': [
          lugar.nome,
          lugar.categoriaExibicao,
          if (lugar.descricao.isNotEmpty) lugar.descricao,
          if (lugar.endereco.isNotEmpty) lugar.endereco,
          if (lugar.temCoordenadas) linkMapa(lugar).toString(),
          'Compartilhado pelo Guia Turismo GB',
        ].join('\n\n'),
      });
}
