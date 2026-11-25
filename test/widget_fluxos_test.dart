import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';
import 'package:guia_turismo/screens/lugares_screen.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';
import 'package:guia_turismo/services/lugares_services.dart';
import 'package:guia_turismo/widgets/cartao_lugar.dart';
import 'package:guia_turismo/widgets/mapa_lugares.dart';

const parque = LugaresModel(
  id: 1,
  nome: 'Parque Central',
  latitude: -23.5,
  longitude: -47,
  categoria: 'Parques',
);
const museu = LugaresModel(
  id: 2,
  nome: 'Museu Municipal',
  latitude: -23.6,
  longitude: -47.1,
  categoria: 'Museus',
);

class ApiWidgetFake extends LugaresServices {
  @override
  Future<List<LugaresModel>> buscarLugares() async => [parque, museu];
}

class TilesMemoria extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7',
        ),
      );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('busca e categoria filtram a lista sem erro de layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lugares = LugaresController(
      usuarioId: 'teste',
      service: ApiWidgetFake(),
    );
    final gps = GpsController();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: lugares),
          ChangeNotifierProvider.value(value: gps),
        ],
        child: const MaterialApp(home: LugaresScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Parque Central'), findsOneWidget);
    expect(find.text('Museu Municipal'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Museu');
    await tester.pump();
    expect(find.text('Parque Central'), findsNothing);
    expect(find.text('Museu Municipal'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parques').last);
    await tester.pumpAndSettle();
    expect(find.text('Parque Central'), findsOneWidget);
    expect(find.text('Museu Municipal'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    lugares.dispose();
    gps.dispose();
  });
  testWidgets('favoritar atualiza a tela de favoritos', (tester) async {
    final lugares = LugaresController(
      usuarioId: 'teste',
      service: ApiWidgetFake(),
    );
    await lugares.listarLugares();
    await lugares.alternarFavorito(parque);
    final gps = GpsController();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: lugares),
          ChangeNotifierProvider.value(value: gps),
        ],
        child: const MaterialApp(home: LugaresScreen(somenteFavoritos: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Parque Central'), findsOneWidget);
    expect(find.text('Museu Municipal'), findsNothing);
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    expect(find.text('Parque Central'), findsNothing);
    expect(lugares.favoritos, isEmpty);
    await tester.pumpWidget(const SizedBox());
    lugares.dispose();
    gps.dispose();
  });
  testWidgets('detalhes acessam os providers e abrem rota e compartilhamento', (
    tester,
  ) async {
    final lugares = LugaresController(
      usuarioId: 'teste',
      service: ApiWidgetFake(),
    );
    await lugares.listarLugares();
    final gps = GpsController();
    final chamadas = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(DispositivoService.canal, (call) async {
      chamadas.add(call.method);
      return null;
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: lugares),
          ChangeNotifierProvider.value(value: gps),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CartaoLugar(lugar: parque)),
        ),
      ),
    );
    await tester.tap(find.text('Parque Central'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Como chegar'));
    await tester.tap(find.text('Como chegar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Compartilhar lugar'));
    await tester.tap(find.text('Compartilhar lugar'));
    await tester.pumpAndSettle();
    expect(chamadas, ['abrirUrl', 'compartilhar']);
    expect(tester.takeException(), isNull);
    messenger.setMockMethodCallHandler(DispositivoService.canal, null);
    await tester.pumpWidget(const SizedBox());
    lugares.dispose();
    gps.dispose();
  });
  testWidgets(
    'mapa mostra pin válido e usuário, sem pin para coordenada nula',
    (tester) async {
      final semCoordenada = LugaresModel.fromJson({
        'id': 3,
        'nome': 'Sem localização',
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaLugares(
              lugares: [parque, semCoordenada],
              tileProvider: TilesMemoria(),
              posicao: PosicaoUsuario(
                latitude: -23.5,
                longitude: -47,
                precisao: 10,
                instante: DateTime(2026),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Parque Central'), findsOneWidget);
      expect(find.byTooltip('Sua localização atual'), findsOneWidget);
      expect(find.byTooltip('Sem localização'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
