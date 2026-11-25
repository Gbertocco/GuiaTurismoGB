import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/models/lugares_model.dart';

class ArmazenamentoService {
  final Future<SharedPreferences> Function() _abrir;
  ArmazenamentoService({Future<SharedPreferences> Function()? abrir})
    : _abrir = abrir ?? SharedPreferences.getInstance;
  Future<List<LugaresModel>> lerLugares(String chave) async {
    final texto = (await _abrir()).getString(chave);
    if (texto == null) return [];
    final dados = jsonDecode(texto);
    if (dados is! List) throw const FormatException('Dados locais inválidos.');
    final lugares = <LugaresModel>[];
    for (final item in dados) {
      if (item is! Map) continue;
      try {
        lugares.add(LugaresModel.fromJson(Map<String, dynamic>.from(item)));
      } catch (erro) {
        debugPrint('Registro local inválido: $erro');
      }
    }
    return lugares;
  }

  Future<void> salvarLugares(String chave, List<LugaresModel> lugares) async {
    final ok = await (await _abrir()).setString(
      chave,
      jsonEncode(lugares.map((lugar) => lugar.toStorageJson()).toList()),
    );
    if (!ok) throw Exception('Não foi possível salvar os lugares no aparelho.');
  }

  Future<Set<String>> lerFavoritos(String usuarioId) async =>
      ((await _abrir()).getStringList('favoritos_v2_$usuarioId') ?? []).toSet();
  Future<void> salvarFavoritos(String usuarioId, Set<String> chaves) async {
    final ok = await (await _abrir()).setStringList(
      'favoritos_v2_$usuarioId',
      chaves.toList()..sort(),
    );
    if (!ok) throw Exception('Não foi possível salvar o favorito.');
  }
}
