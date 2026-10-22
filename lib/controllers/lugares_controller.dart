import 'package:flutter/material.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/services/session_service.dart';

class LugaresController extends ChangeNotifier {
  final LugaresServices _service;
  bool carregando = false;
  bool salvando = false;
  String erro = '';
  String erroCadastro = '';
  List<LugaresModel> _lugares = [];
  List<LugaresModel> get lugares => _lugares;

  LugaresController({LugaresServices? service})
    : _service = service ?? LugaresServices();

  Future<void> listarLugares() async {
    if (carregando) return;
    carregando = true;
    erro = '';
    notifyListeners();

    try {
      _lugares = await _service.buscarLugares();
    } catch (e) {
      erro = e.toString().replaceFirst('Exception: ', '');
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> cadastrarLugar(LugaresModel dados) async {
    if (salvando) return false;
    salvando = true;
    erroCadastro = '';
    notifyListeners();

    try {
      const configurado = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MTMsImlhdCI6MTc5MjY3NTcxMCwiZXhwIjoxNzkyNzYyMTEwfQ.QyINasK9e2agxi8zKs_MG0krwSe3qigAil3eu1wbnNg';
      String token = configurado;

      if (token.isEmpty) {
        token = await SessionService().pegarToken() ?? '';
      }

      await _service.cadastrarLugar(dados, token);
      return true;
    } catch (e) {
      erroCadastro = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }
}
