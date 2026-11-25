import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:guia_turismo/services/dispositivo_service.dart';

class FotosService {
  final ImagePicker _picker;
  final DispositivoService _dispositivo;
  FotosService({ImagePicker? picker, DispositivoService? dispositivo})
    : _picker = picker ?? ImagePicker(),
      _dispositivo = dispositivo ?? DispositivoService();
  Future<XFile?> selecionar(ImageSource origem) => _picker.pickImage(
    source: origem,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 80,
  );
  Future<XFile?> recuperarFoto() async {
    final dados = await _picker.retrieveLostData();
    if (dados.exception != null) throw dados.exception!;
    return dados.files?.firstOrNull;
  }

  Future<String> guardar(String temporaria, String usuarioId) async {
    final raiz = await _dispositivo.diretorioDocumentos();
    final usuario = usuarioId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final pasta = Directory('$raiz/fotos/$usuario');
    await pasta.create(recursive: true);
    final extensao = temporaria.split('.').last.toLowerCase();
    final sufixo = {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extensao)
        ? extensao
        : 'jpg';
    final destino =
        '${pasta.path}/${DateTime.now().microsecondsSinceEpoch}.$sufixo';
    await File(temporaria).copy(destino);
    return destino;
  }
}
