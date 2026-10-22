import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String mensagem;
  final int? statusCode;
  const ApiException(this.mensagem, {this.statusCode});
  @override
  String toString() => mensagem;
}

class ApiClient {
  static const baseUrl = 'https://guia.liliaborges.com.br';
  final http.Client _client;
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> get(
    String caminho, {
    Map<String, String>? parametros,
  }) => _enviar('GET', caminho, parametros: parametros);

  Future<Map<String, dynamic>> post(
    String caminho, {
    required Map<String, dynamic> dados,
    String? token,
  }) => _enviar('POST', caminho, dados: dados, token: token);

  Future<Map<String, dynamic>> _enviar(
    String metodo,
    String caminho, {
    Map<String, String>? parametros,
    Map<String, dynamic>? dados,
    String? token,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$caminho',
    ).replace(queryParameters: parametros);
    final headers = {
      'Accept': 'application/json',
      if (dados != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final resposta =
          await (metodo == 'GET'
                  ? _client.get(uri, headers: headers)
                  : _client.post(
                      uri,
                      headers: headers,
                      body: jsonEncode(dados),
                    ))
              .timeout(const Duration(seconds: 30));
      Map<String, dynamic> corpo = {};
      try {
        final valor = jsonDecode(utf8.decode(resposta.bodyBytes));
        if (valor is Map<String, dynamic>) corpo = valor;
      } on FormatException {
        // Uma página de erro do servidor pode não ser JSON.
      }
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        final mensagem = corpo['message'] ?? corpo['mensagem'];
        throw ApiException(
          mensagem is String && mensagem.isNotEmpty
              ? mensagem
              : switch (resposta.statusCode) {
                  401 => 'Cadastro não autorizado pela API.',
                  403 => 'Seu usuário não tem permissão para esta ação.',
                  _ =>
                    'Não foi possível concluir a solicitação (HTTP ${resposta.statusCode}).',
                },
          statusCode: resposta.statusCode,
        );
      }
      return corpo;
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }
}
