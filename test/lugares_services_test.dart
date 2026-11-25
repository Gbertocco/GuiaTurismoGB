import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:guia_turismo/services/lugares_services.dart';

Map<String, dynamic> registro(int id) => {
  'id': id,
  'nome': 'Lugar $id',
  'latitude': -23,
  'longitude': -47,
};
void main() {
  test('usa limite 100 e busca páginas restantes sem perder pins', () async {
    final paginas = <int>[];
    final service = LugaresServices(
      client: MockClient((request) async {
        expect(request.url.queryParameters['limite'], '100');
        final pagina = int.parse(request.url.queryParameters['pagina']!);
        paginas.add(pagina);
        return http.Response(
          jsonEncode({
            'data': List.generate(
              pagina == 3 ? 23 : 100,
              (i) => registro((pagina - 1) * 100 + i + 1),
            ),
          }),
          200,
        );
      }),
    );
    final lugares = await service.buscarLugares();
    expect(lugares.length, 223);
    expect(paginas, [1, 2, 3]);
    service.dispose();
  });
  test('encerra quando o servidor repete a mesma página', () async {
    var requisicoes = 0;
    final service = LugaresServices(
      client: MockClient((_) async {
        requisicoes++;
        return http.Response(
          jsonEncode({'data': List.generate(100, registro)}),
          200,
        );
      }),
    );
    expect((await service.buscarLugares()).length, 100);
    expect(requisicoes, 2);
    service.dispose();
  });
  test(
    'obedece total de páginas mesmo quando a API devolve menos que o limite',
    () async {
      var requisicoes = 0;
      final service = LugaresServices(
        client: MockClient((_) async {
          requisicoes++;
          return http.Response(
            jsonEncode({
              'data': [registro(requisicoes)],
              'paginacao': {'totalPaginas': 2},
            }),
            200,
          );
        }),
      );
      expect((await service.buscarLugares()).length, 2);
      service.dispose();
    },
  );
  test('um registro sem coordenadas não derruba os outros', () async {
    final service = LugaresServices(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              registro(1),
              {'id': 2, 'nome': 'Sem coordenadas'},
              registro(3),
            ],
          }),
          200,
        ),
      ),
    );
    final lugares = await service.buscarLugares();
    expect(lugares.length, 3);
    expect(lugares.where((l) => l.temCoordenadas).length, 2);
    service.dispose();
  });
  test('HTML no lugar de JSON produz erro tratável', () async {
    final service = LugaresServices(
      client: MockClient((_) async => http.Response('<html>erro</html>', 200)),
    );
    await expectLater(
      service.buscarLugares(),
      throwsA(predicate((e) => '$e'.contains('dados inválidos'))),
    );
    service.dispose();
  });
  test('erro HTTP produz mensagem tratável', () async {
    final service = LugaresServices(
      client: MockClient((_) async => http.Response('', 503)),
    );
    await expectLater(service.buscarLugares(), throwsException);
    service.dispose();
  });
}
