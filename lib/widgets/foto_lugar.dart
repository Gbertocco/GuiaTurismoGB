import 'dart:io';
import 'package:flutter/material.dart';
import 'package:guia_turismo/models/lugares_model.dart';

class FotoLugar extends StatelessWidget {
  final LugaresModel lugar;
  final double altura;
  final double? largura;
  final double raio;
  const FotoLugar({
    super.key,
    required this.lugar,
    this.altura = 200,
    this.largura,
    this.raio = 12,
  });
  Widget _semFoto(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.landscape_outlined,
        size: altura < 70 ? 24 : 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
  Widget _remota(BuildContext context) => lugar.fotoUrl.isEmpty
      ? _semFoto(context)
      : Image.network(
          lugar.fotoUrl,
          fit: BoxFit.cover,
          cacheWidth: altura < 100 ? 180 : 1000,
          errorBuilder: (_, error, stack) => _semFoto(context),
        );
  @override
  Widget build(BuildContext context) => Semantics(
    label: lugar.temFoto
        ? 'Foto de ${lugar.nome}'
        : '${lugar.nome}, sem foto disponível',
    child: SizedBox(
      height: altura,
      width: largura,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: lugar.fotoLocal.isNotEmpty
            ? Image.file(
                File(lugar.fotoLocal),
                fit: BoxFit.cover,
                cacheWidth: altura < 100 ? 180 : 1000,
                errorBuilder: (_, error, stack) => _remota(context),
              )
            : _remota(context),
      ),
    ),
  );
}
