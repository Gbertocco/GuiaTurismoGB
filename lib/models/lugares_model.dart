class LugaresModel {
  final int id;
  final String nome;
  final String categoria;
  final int? categoriaId;
  // A API pode retornar int ou double, como indicado pela professora.
  final num latitude;
  final num longitude;
  final String descricao;
  final String endereco;
  final String fotoUrl;
  final String fotoLocal;
  final bool coordenadasInformadas;
  final bool apenasNesteDispositivo;

  const LugaresModel({
    this.id = 0,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.categoriaId,
    this.categoria = '',
    this.descricao = '',
    this.endereco = '',
    this.fotoUrl = '',
    this.fotoLocal = '',
    this.coordenadasInformadas = true,
    this.apenasNesteDispositivo = false,
  });

  bool get temCoordenadas =>
      coordenadasInformadas &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
  bool get temFoto => fotoLocal.isNotEmpty || fotoUrl.isNotEmpty;
  String get categoriaExibicao => categoria.isEmpty ? 'Outros' : categoria;
  String get chave => id != 0
      ? '${id > 0 ? 'api' : 'local'}:$id'
      : 'lugar:$nome:$latitude:$longitude';

  static num? _numero(dynamic valor) {
    final numero = valor is num
        ? valor
        : num.tryParse('$valor'.trim().replaceAll(',', '.'));
    return numero != null && numero.isFinite ? numero : null;
  }

  static int? _inteiro(dynamic valor) => _numero(valor)?.toInt();
  static String _foto(dynamic valor) {
    if (valor is List) {
      for (final item in valor) {
        final foto = _foto(item);
        if (foto.isNotEmpty) return foto;
      }
      return '';
    }
    if (valor is Map) {
      return _foto([
        valor['urlFoto'],
        valor['url'],
        valor['caminho'],
        valor['foto'],
        valor['fotoUrl'],
      ]);
    }
    if (valor is! String || valor.trim().isEmpty) return '';
    final uri = Uri.tryParse(valor.trim());
    if (uri == null) return '';
    if (!uri.hasScheme) {
      return Uri.parse(
        'https://guia.liliaborges.com.br/',
      ).resolveUri(uri).toString();
    }
    return uri.scheme == 'https' || uri.scheme == 'http' ? uri.toString() : '';
  }

  factory LugaresModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    final lat = _numero(json['latitude']);
    final lng = _numero(json['longitude']);
    return LugaresModel(
      id: _inteiro(json['id']) ?? 0,
      nome: '${json['nome'] ?? 'Lugar sem nome'}',
      // Ausências recebem 0, mas a flag impede um pin falso em (0, 0).
      latitude: lat ?? 0,
      longitude: lng ?? 0,
      coordenadasInformadas:
          json['coordenadasInformadas'] != false && lat != null && lng != null,
      descricao: '${json['descricao'] ?? ''}',
      endereco: '${json['endereco'] ?? ''}',
      categoriaId: _inteiro(
        json['categoriaId'] ??
            json['categoria_id'] ??
            (categoria is Map ? categoria['id'] : null),
      ),
      categoria: categoria is Map
          ? '${categoria['nome'] ?? ''}'
          : categoria is String
          ? categoria
          : '${json['categoriaNome'] ?? ''}',
      fotoUrl: _foto([
        json['fotoUrl'],
        json['foto_url'],
        json['foto'],
        json['urlFoto'],
        json['imagemUrl'],
        json['imagem'],
        json['fotos'],
        json['galeria'],
      ]),
      fotoLocal: '${json['fotoLocal'] ?? ''}',
      apenasNesteDispositivo: json['apenasNesteDispositivo'] == true,
    );
  }
  LugaresModel copyWith({
    int? id,
    String? fotoLocal,
    String? fotoUrl,
    bool? apenasNesteDispositivo,
  }) => LugaresModel(
    id: id ?? this.id,
    nome: nome,
    latitude: latitude,
    longitude: longitude,
    categoriaId: categoriaId,
    categoria: categoria,
    descricao: descricao,
    endereco: endereco,
    fotoUrl: fotoUrl ?? this.fotoUrl,
    fotoLocal: fotoLocal ?? this.fotoLocal,
    coordenadasInformadas: coordenadasInformadas,
    apenasNesteDispositivo:
        apenasNesteDispositivo ?? this.apenasNesteDispositivo,
  );
  // Mantém o contrato já utilizado pela API da disciplina.
  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
    'latitude': latitude,
    'longitude': longitude,
    'categoriaId': categoriaId,
  };
  Map<String, dynamic> toStorageJson() => {
    ...toJson(),
    'id': id,
    'categoria': categoria,
    'endereco': endereco,
    'fotoUrl': fotoUrl,
    'fotoLocal': fotoLocal,
    'coordenadasInformadas': coordenadasInformadas,
    'apenasNesteDispositivo': apenasNesteDispositivo,
  };
}
