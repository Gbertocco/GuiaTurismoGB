import 'dart:convert';

import 'package:guia_turismo/models/lugares_model.dart';
import 'package:http/http.dart' as http;

class LugaresServices {
  String endpoint = "https://guiaturismo.onrender.com/";
  int pagina = 1;
  int limite = 10;

  Future<List<LugaresModel>> buscarLugares() async {
    try {
      final response = await http.get(
        Uri.parse('$endpoint?pagina=$pagina&limite=$limite'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData =
            jsonDecode(response.body);

        final List<dynamic> data = responseData['data'];

        return data
            .map((item) => LugaresModel.fromJson(item))
            .toList();
      } else {
        throw Exception('Erro na requisição: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}