import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';

class GpsController extends ChangeNotifier {
  final DispositivoService _service;
  Timer? _timer;
  bool _descartado = false;
  bool carregando = false;
  PosicaoUsuario? posicao;
  String erro = '', codigoErro = '';
  GpsController({DispositivoService? service})
    : _service = service ?? DispositivoService();
  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  Future<void> atualizar({bool solicitarPermissao = true}) async {
    if (carregando || _descartado) return;
    carregando = true;
    erro = '';
    codigoErro = '';
    _avisar();
    try {
      posicao = await _service.obterPosicao(
        solicitarPermissao: solicitarPermissao,
      );
    } on PlatformException catch (e) {
      codigoErro = e.code;
      erro = switch (e.code) {
        'GPS_DESLIGADO' =>
          'Ative a localização do aparelho para mostrar sua posição.',
        'PERMISSAO_NEGADA' => 'Permita o acesso à localização para usar o GPS.',
        'PERMISSAO_BLOQUEADA' =>
          'Libere a localização nas configurações do aplicativo.',
        'GPS_TIMEOUT' =>
          'Ainda não foi possível obter o GPS. Tente em um local aberto.',
        'CANCELADO' => '',
        _ => 'Não foi possível obter a localização. Tente novamente.',
      };
    } on MissingPluginException {
      erro = 'Reinicie o app Android para ativar os recursos do dispositivo.';
    } on TimeoutException {
      erro = 'O GPS demorou para responder. Tente novamente.';
    } catch (_) {
      erro = 'Não foi possível obter uma localização válida.';
    } finally {
      carregando = false;
      _avisar();
    }
  }

  void iniciar({bool solicitarPermissao = true}) {
    parar();
    unawaited(atualizar(solicitarPermissao: solicitarPermissao));
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(atualizar(solicitarPermissao: false));
    });
  }

  Future<void> abrirConfiguracoes() async {
    try {
      if (codigoErro == 'GPS_DESLIGADO') {
        await _service.abrirConfiguracoesGps();
      } else {
        await _service.abrirConfiguracoesApp();
      }
    } catch (_) {
      erro = 'Não foi possível abrir as configurações.';
      _avisar();
    }
  }

  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _descartado = true;
    parar();
    super.dispose();
  }
}
