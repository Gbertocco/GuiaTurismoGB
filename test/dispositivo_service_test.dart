import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(DispositivoService.canal, null),
  );
  test('GPS converte resposta nativa para posição do usuário', () async {
    messenger.setMockMethodCallHandler(
      DispositivoService.canal,
      (call) async => {
        'latitude': -23.5,
        'longitude': -47,
        'accuracy': 8,
        'timestamp': 1790000000000,
      },
    );
    final gps = GpsController();
    await gps.atualizar();
    expect(gps.posicao?.latitude, -23.5);
    expect(gps.erro, isEmpty);
    expect(gps.carregando, isFalse);
    gps.dispose();
  });
  test('permissão negada é tratada sem lançar exceção na tela', () async {
    messenger.setMockMethodCallHandler(
      DispositivoService.canal,
      (call) async => throw PlatformException(code: 'PERMISSAO_NEGADA'),
    );
    final gps = GpsController();
    await gps.atualizar();
    expect(gps.erro, contains('Permita'));
    expect(gps.posicao, isNull);
    expect(gps.carregando, isFalse);
    gps.dispose();
  });
  test('GPS desligado mostra ação para configurações', () async {
    messenger.setMockMethodCallHandler(
      DispositivoService.canal,
      (call) async => throw PlatformException(code: 'GPS_DESLIGADO'),
    );
    final gps = GpsController();
    await gps.atualizar();
    expect(gps.codigoErro, 'GPS_DESLIGADO');
    expect(gps.erro, contains('Ative'));
    gps.dispose();
  });
  test('Como chegar envia destino válido para navegação externa', () async {
    MethodCall? enviada;
    messenger.setMockMethodCallHandler(DispositivoService.canal, (call) async {
      enviada = call;
      return null;
    });
    await DispositivoService().comoChegar(
      const LugaresModel(nome: 'Museu', latitude: -23.5, longitude: -47),
    );
    expect(enviada?.method, 'abrirUrl');
    final uri = Uri.parse((enviada!.arguments as Map)['url'] as String);
    expect(uri.queryParameters['destination'], '-23.5,-47');
    expect(uri.queryParameters['api'], '1');
  });
  test('não abre rota com coordenada ausente', () async {
    await expectLater(
      DispositivoService().comoChegar(
        LugaresModel.fromJson({'nome': 'Sem GPS'}),
      ),
      throwsFormatException,
    );
  });
  test('compartilha nome e link do lugar pelo seletor nativo', () async {
    MethodCall? enviada;
    messenger.setMockMethodCallHandler(DispositivoService.canal, (call) async {
      enviada = call;
      return null;
    });
    await DispositivoService().compartilhar(
      const LugaresModel(nome: 'Museu', latitude: -23.5, longitude: -47),
    );
    expect(enviada?.method, 'compartilhar');
    expect((enviada!.arguments as Map)['texto'], contains('Museu'));
    expect(
      (enviada!.arguments as Map)['texto'],
      contains('https://www.google.com/maps/search/'),
    );
  });
}
