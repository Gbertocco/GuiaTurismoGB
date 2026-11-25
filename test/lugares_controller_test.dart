import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/models/lugares_model.dart';
import 'package:guia_turismo/services/armazenamento_service.dart';
import 'package:guia_turismo/services/fotos_service.dart';
import 'package:guia_turismo/services/lugares_services.dart';

const parque = LugaresModel(
  id: 1,
  nome: 'Parque',
  latitude: -23,
  longitude: -47,
  categoria: 'Parques',
  categoriaId: 1,
);

class ApiFake extends LugaresServices {
  final bool falhar;
  ApiFake({this.falhar = false});
  @override
  Future<List<LugaresModel>> buscarLugares() async {
    if (falhar) throw Exception('Sem internet');
    return [parque];
  }

  @override
  Future<LugaresModel> cadastrarLugar(LugaresModel lugar, String token) async =>
      lugar.copyWith(id: 99, apenasNesteDispositivo: false);
}

class FotosFake extends FotosService {
  @override
  Future<String> guardar(String temporaria, String usuarioId) async =>
      '/fotos/$usuarioId/foto.jpg';
}

class FalhaFavoritos extends ArmazenamentoService {
  @override
  Future<void> salvarFavoritos(String usuarioId, Set<String> chaves) async =>
      throw Exception('Disco cheio');
}

class LeituraLenta extends ArmazenamentoService {
  final liberacao = Completer<void>();
  @override
  Future<List<LugaresModel>> lerLugares(String chave) async {
    if (chave.startsWith('meus_')) await liberacao.future;
    return super.lerLugares(chave);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('favorito permanece após reconstruir o controller', () async {
    final a = LugaresController(usuarioId: 'ana', service: ApiFake());
    await a.listarLugares();
    expect(await a.alternarFavorito(parque), isTrue);
    a.dispose();
    final b = LugaresController(usuarioId: 'ana', service: ApiFake());
    await b.listarLugares();
    expect(b.ehFavorito(parque), isTrue);
    b.dispose();
  });
  test('favoritos são separados por conta Google', () async {
    final a = LugaresController(usuarioId: 'ana', service: ApiFake());
    await a.listarLugares();
    await a.alternarFavorito(parque);
    final b = LugaresController(usuarioId: 'bia', service: ApiFake());
    await b.listarLugares();
    expect(b.ehFavorito(parque), isFalse);
    a.dispose();
    b.dispose();
  });
  test('falha ao persistir favorito reverte o coração', () async {
    final c = LugaresController(
      usuarioId: 'ana',
      service: ApiFake(),
      armazenamento: FalhaFavoritos(),
    );
    await c.listarLugares();
    expect(await c.alternarFavorito(parque), isFalse);
    expect(c.ehFavorito(parque), isFalse);
    c.dispose();
  });
  test('sem rede, usa cache e informa a indisponibilidade', () async {
    await ArmazenamentoService().salvarLugares('lugares_api_cache_v2', [
      parque,
    ]);
    final c = LugaresController(
      usuarioId: 'ana',
      service: ApiFake(falhar: true),
    );
    await c.listarLugares();
    expect(c.lugares.length, 1);
    expect(c.aviso, contains('API indisponível'));
    expect(c.erro, isEmpty);
    c.dispose();
  });
  test('cadastro com foto permanece sem token e após reiniciar', () async {
    final a = LugaresController(
      usuarioId: 'ana',
      service: ApiFake(falhar: true),
      fotos: FotosFake(),
    );
    expect(
      await a.cadastrarLugar(parque, fotoTemporaria: '/temporaria.jpg'),
      isTrue,
    );
    final salvo = a.lugares.single;
    expect(salvo.fotoLocal, '/fotos/ana/foto.jpg');
    expect(salvo.apenasNesteDispositivo, isTrue);
    a.dispose();
    final b = LugaresController(
      usuarioId: 'ana',
      service: ApiFake(falhar: true),
    );
    await b.listarLugares();
    expect(b.lugares.single.fotoLocal, salvo.fotoLocal);
    b.dispose();
  });
  test('cadastro sem foto não é confirmado', () async {
    final c = LugaresController(
      usuarioId: 'ana',
      service: ApiFake(),
      fotos: FotosFake(),
    );
    expect(await c.cadastrarLugar(parque), isFalse);
    expect(c.erroCadastro, contains('foto'));
    c.dispose();
  });
  test(
    'cadastro não perde registros quando a leitura inicial está em andamento',
    () async {
      final armazenamento = LeituraLenta();
      await ArmazenamentoService().salvarLugares('meus_lugares_v2_ana', [
        parque.copyWith(id: -1),
      ]);
      final c = LugaresController(
        usuarioId: 'ana',
        service: ApiFake(falhar: true),
        fotos: FotosFake(),
        armazenamento: armazenamento,
      );
      final leitura = c.listarLugares();
      final cadastro = c.cadastrarLugar(
        parque,
        fotoTemporaria: '/temporaria.jpg',
      );
      armazenamento.liberacao.complete();
      await leitura;
      expect(await cadastro, isTrue);
      expect(c.lugares.length, 2);
      c.dispose();
    },
  );
  test(
    'dados locais corrompidos são preservados em vez de sobrescritos',
    () async {
      SharedPreferences.setMockInitialValues({
        'meus_lugares_v2_ana': 'conteudo corrompido',
      });
      final c = LugaresController(
        usuarioId: 'ana',
        service: ApiFake(),
        fotos: FotosFake(),
      );
      expect(
        await c.cadastrarLugar(parque, fotoTemporaria: '/temporaria.jpg'),
        isFalse,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          'meus_lugares_v2_ana',
        ),
        'conteudo corrompido',
      );
      c.dispose();
    },
  );
}
