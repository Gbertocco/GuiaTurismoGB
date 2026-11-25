import 'package:flutter_test/flutter_test.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/models/posicao_usuario.dart';

void main() {
  group('Coordenadas recebidas da API', () {
    test('aceita inteiros e categoria como objeto', () {
      final lugar = LugaresModel.fromJson({
        'id': 1,
        'nome': 'Parque',
        'latitude': -23,
        'longitude': -47,
        'categoria': {'id': 2, 'nome': 'Parques'},
      });
      expect(lugar.latitude, isA<num>());
      expect(lugar.temCoordenadas, isTrue);
      expect(lugar.categoria, 'Parques');
      expect(lugar.categoriaId, 2);
    });
    test('aceita double e números como texto, inclusive vírgula', () {
      final lugar = LugaresModel.fromJson({
        'id': '2',
        'latitude': '-23,5',
        'longitude': -47.1,
        'categoria': 'Museus',
      });
      expect(lugar.latitude, -23.5);
      expect(lugar.temCoordenadas, isTrue);
      expect(lugar.categoria, 'Museus');
    });
    test('null recebe zero sem produzir pin falso', () {
      final lugar = LugaresModel.fromJson({
        'id': 3,
        'latitude': null,
        'longitude': null,
      });
      expect(lugar.latitude, 0);
      expect(lugar.longitude, 0);
      expect(lugar.temCoordenadas, isFalse);
      expect(
        LugaresModel.fromJson(lugar.toStorageJson()).temCoordenadas,
        isFalse,
      );
    });
    test('zero explicitamente informado continua sendo coordenada válida', () {
      final lugar = LugaresModel.fromJson({'latitude': 0, 'longitude': 0});
      expect(lugar.temCoordenadas, isTrue);
    });
    for (final valor in ['inválido', 'NaN', double.infinity, 1000]) {
      test('não cria pin para latitude inválida $valor', () {
        final lugar = LugaresModel.fromJson({
          'latitude': valor,
          'longitude': -47,
        });
        expect(lugar.temCoordenadas, isFalse);
      });
    }
    test('preserva foto, identificação e categoria no armazenamento', () {
      const original = LugaresModel(
        id: -20,
        nome: 'Museu',
        latitude: -23,
        longitude: -47,
        fotoLocal: '/fotos/museu.jpg',
        categoria: 'Museus',
        apenasNesteDispositivo: true,
      );
      final salvo = LugaresModel.fromJson(original.toStorageJson());
      expect(salvo.chave, original.chave);
      expect(salvo.fotoLocal, original.fotoLocal);
      expect(salvo.apenasNesteDispositivo, isTrue);
      expect(salvo.categoria, original.categoria);
    });
    test('reconhece foto remota e rejeita esquema executável', () {
      expect(
        LugaresModel.fromJson({'foto': '/uploads/a.jpg'}).fotoUrl,
        'https://guia.liliaborges.com.br/uploads/a.jpg',
      );
      expect(
        LugaresModel.fromJson({'foto': 'javascript:alert(1)'}).fotoUrl,
        isEmpty,
      );
    });
  });
  group('Distância em linha reta', () {
    final posicao = PosicaoUsuario(
      latitude: 0,
      longitude: 0,
      precisao: 5,
      instante: DateTime(2026),
    );
    test('mesmo ponto resulta em zero', () {
      expect(
        posicao.distanciaAte(
          const LugaresModel(nome: 'Origem', latitude: 0, longitude: 0),
        ),
        0,
      );
    });
    test('um grau no equador equivale a cerca de 111 km', () {
      expect(
        posicao.distanciaAte(
          const LugaresModel(nome: 'Destino', latitude: 0, longitude: 1),
        ),
        closeTo(111195, 10),
      );
    });
    test('coordenadas ausentes não produzem distância inventada', () {
      expect(
        posicao.distanciaAte(LugaresModel.fromJson({'nome': 'Sem GPS'})),
        isNull,
      );
    });
    test('formata metros e quilômetros em português', () {
      expect(formatarDistancia(250), '250 m');
      expect(formatarDistancia(1500), '1,5 km');
      expect(formatarDistancia(null), 'Distância indisponível');
    });
  });
}
