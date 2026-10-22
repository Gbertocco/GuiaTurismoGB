import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> chamarGaleria() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imagem == null) return null;

    return File(imagem.path);
  }

  Future<File?> chamarCamera() async {
    final XFile? imagem = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (imagem == null) return null;

    return File(imagem.path);
  }
}