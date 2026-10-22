import 'dart:convert';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;

class LugaresServices {
  final String url = 'https://guia.liliaborges.com.br/lugares';
  final http.Client _client;

  LugaresServices({http.Client? client}) : _client = client ?? http.Client();

  Future<List<LugaresModel>> buscarLugares() async {
    final resposta = await _client
        .get(Uri.parse('$url?pagina=1&limite=10'))
        .timeout(const Duration(seconds: 30));

    if (resposta.statusCode != 200) {
      throw Exception('Não foi possível carregar os lugares.');
    }

    final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
    final List lista = dados['data'];
    return lista.map((item) => LugaresModel.fromJson(item)).toList();
  }

  Future<void> cadastrarLugar(LugaresModel lugar, String token) async {
    if (token.trim().isEmpty) {
      throw Exception('Cadastro não autorizado pela API.');
    }

    final resposta = await _client
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(lugar.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (resposta.statusCode == 200 || resposta.statusCode == 201) {
      return;
    }

    if (resposta.statusCode == 401) {
      throw Exception('Cadastro não autorizado pela API.');
    }

    String mensagem = 'Não foi possível cadastrar o lugar.';
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is Map && dados['message'] is String) {
        mensagem = dados['message'];
      }
    } on FormatException {
      mensagem = 'Não foi possível cadastrar o lugar.';
    }
    throw Exception(mensagem);
  }
}
