import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;

class LocalizacaoService {
  static const url = String.fromEnvironment(
    'NOMINATIM_URL',
    defaultValue: 'https://nominatim.openstreetmap.org/search',
  );
  final http.Client _client;
  final Map<String, List<LugaresModel>> _cache = {};
  static DateTime? _ultimaBusca;

  LocalizacaoService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<LugaresModel>> buscarEndereco(String endereco) async {
    final busca = endereco.trim();
    if (busca.isEmpty) {
      throw Exception('Informe um endereço ou CEP.');
    }
    if (_cache.containsKey(busca)) return _cache[busca]!;

    // O Nominatim permite no máximo uma busca por segundo.
    if (_ultimaBusca != null) {
      final tempo = DateTime.now().difference(_ultimaBusca!);
      if (tempo < const Duration(seconds: 1)) {
        await Future<void>.delayed(const Duration(seconds: 1) - tempo);
      }
    }
    _ultimaBusca = DateTime.now();

    final cep = busca.replaceAll(RegExp(r'[\s-]'), '');
    final ehCep = RegExp(r'^\d{8}$').hasMatch(cep);
    final uri = Uri.parse(url).replace(
      queryParameters: {
        'format': 'jsonv2',
        'limit': '5',
        'accept-language': 'pt-BR',
        if (ehCep) ...{
          'postalcode': '${cep.substring(0, 5)}-${cep.substring(5)}',
          'countrycodes': 'br',
        } else
          'q': busca,
      },
    );

    try {
      final resposta = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (!kIsWeb)
                'User-Agent':
                    'GuiaTurismoGB/1.0 (+https://github.com/Gbertocco/GuiaTurismoGB)',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (resposta.statusCode == 429) {
        throw Exception('Aguarde alguns segundos e tente buscar novamente.');
      }
      if (resposta.statusCode != 200) {
        throw Exception('Não foi possível buscar o endereço. Tente novamente.');
      }

      final List dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      final locais = dados
          .map(
            (item) => LugaresModel(
              nome: item['display_name'] as String,
              latitude: double.parse(item['lat'].toString()),
              longitude: double.parse(item['lon'].toString()),
            ),
          )
          .toList();
      _cache[busca] = locais;
      return locais;
    } on TimeoutException {
      throw Exception('A busca demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw Exception('Verifique sua internet e tente buscar novamente.');
    } on FormatException {
      throw Exception('O serviço retornou uma localização inválida.');
    }
  }

  void dispose() {
    _client.close();
  }
}
