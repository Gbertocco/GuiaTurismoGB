import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/api_client.dart';
import 'package:http/http.dart' as http;

class LugaresServices {
  final String url = 'https://guia.liliaborges.com.br/lugares';
  final http.Client _client;
  LugaresServices({http.Client? client}) : _client = client ?? http.Client();
  Future<List<LugaresModel>> buscarLugares() async {
    final lugares = <String, LugaresModel>{};
    final paginasRecebidas = <String>{};
    const limite = 100; // Correção pedida pela professora.
    try {
      for (var pagina = 1; pagina <= 100; pagina++) {
        final resposta = await _client
            .get(
              Uri.parse('$url?pagina=$pagina&limite=$limite'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 20));
        if (resposta.statusCode != 200) {
          throw const ApiException(
            'Não foi possível carregar os lugares da API.',
          );
        }
        final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
        final dynamic conteudo = dados is Map ? dados['data'] : dados;
        final dynamic lista = conteudo is Map
            ? conteudo['data'] ?? conteudo['items']
            : conteudo;
        if (lista is! List) {
          throw const FormatException('Lista de lugares inválida.');
        }
        if (lista.isEmpty) break;
        if (!paginasRecebidas.add(jsonEncode(lista))) break;
        for (final item in lista) {
          if (item is! Map) continue;
          try {
            final lugar = LugaresModel.fromJson(
              Map<String, dynamic>.from(item),
            );
            lugares[lugar.chave] = lugar;
          } catch (erro) {
            debugPrint('Lugar inválido recebido da API: $erro');
          }
        }
        final meta = dados is Map
            ? dados['pagination'] ?? dados['paginacao'] ?? dados['meta']
            : null;
        final totalPaginas = meta is Map
            ? int.tryParse(
                '${meta['totalPages'] ?? meta['totalPaginas'] ?? meta['last_page']}',
              )
            : null;
        if (totalPaginas != null
            ? pagina >= totalPaginas
            : lista.length < limite) {
          break;
        }
        if (pagina == 100) {
          throw const ApiException(
            'A API excedeu o limite de páginas. Tente novamente.',
          );
        }
      }
      return lugares.values.toList();
    } on TimeoutException {
      throw const ApiException(
        'A API demorou para responder. Verifique a conexão.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar à API. Verifique a internet.',
      );
    } on FormatException {
      throw const ApiException(
        'A API retornou dados inválidos. Tente novamente depois.',
      );
    }
  }

  Future<LugaresModel> cadastrarLugar(LugaresModel lugar, String token) async {
    if (token.trim().isEmpty) {
      throw const ApiException('A API não autorizou a publicação.');
    }
    try {
      final resposta = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(lugar.toJson()),
          )
          .timeout(const Duration(seconds: 20));
      if (resposta.statusCode == 200 || resposta.statusCode == 201) {
        try {
          final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
          final registro = dados is Map ? dados['data'] ?? dados : null;
          if (registro is Map) {
            final id = int.tryParse('${registro['id']}');
            if (id != null && id > 0) {
              return lugar.copyWith(id: id, apenasNesteDispositivo: false);
            }
          }
        } on FormatException {
          /* Pode existir sucesso sem o objeto criado. */
        }
        throw const ApiException(
          'A API não confirmou o identificador do cadastro.',
        );
      }
      if (resposta.statusCode == 401 || resposta.statusCode == 403) {
        throw const ApiException('A API não autorizou a publicação.');
      }
      throw const ApiException('A API não conseguiu publicar este lugar.');
    } on TimeoutException {
      throw const ApiException('A API demorou para responder.');
    } on http.ClientException {
      throw const ApiException('A API está indisponível no momento.');
    }
  }

  void dispose() => _client.close();
}
