import 'package:flutter/material.dart';
import 'package:guia_turismo/services/session_service.dart';

class SessionController extends ChangeNotifier {
  bool carregando = false;
  String erro = "";
  final String _token = "";
  String get token => _token;

  Future<String> verificarToken() async {
    carregando = true;
    notifyListeners();
    String tk = await SessionService().pegarToken() ?? '';
    carregando = false;
    notifyListeners();
    return tk;
  }

}