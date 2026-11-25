import 'dart:math' as math;
import 'package:guia_turismo/models/lugares_model.dart';

class PosicaoUsuario {
  final double latitude;
  final double longitude;
  final double precisao;
  final DateTime instante;
  const PosicaoUsuario({
    required this.latitude,
    required this.longitude,
    required this.precisao,
    required this.instante,
  });
  factory PosicaoUsuario.fromMap(Map<String, dynamic> dados) {
    final lat = (dados['latitude'] as num).toDouble();
    final lng = (dados['longitude'] as num).toDouble();
    if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
      throw const FormatException('O GPS retornou coordenadas inválidas.');
    }
    return PosicaoUsuario(
      latitude: lat,
      longitude: lng,
      precisao: (dados['accuracy'] as num?)?.toDouble() ?? 0,
      instante: DateTime.fromMillisecondsSinceEpoch(
        (dados['timestamp'] as num).toInt(),
      ),
    );
  }
  double? distanciaAte(LugaresModel lugar) {
    if (!lugar.temCoordenadas) return null;
    double rad(num graus) => graus * math.pi / 180;
    final dLat = rad(lugar.latitude - latitude);
    final dLng = rad(lugar.longitude - longitude);
    final a =
        (math.pow(math.sin(dLat / 2), 2) +
                math.cos(rad(latitude)) *
                    math.cos(rad(lugar.latitude)) *
                    math.pow(math.sin(dLng / 2), 2))
            .clamp(0.0, 1.0);
    return 6371000 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

String formatarDistancia(double? metros) {
  if (metros == null || !metros.isFinite) return 'Distância indisponível';
  if (metros < 1000) return '${metros.round()} m';
  return '${(metros / 1000).toStringAsFixed(metros < 10000 ? 1 : 0).replaceAll('.', ',')} km';
}
