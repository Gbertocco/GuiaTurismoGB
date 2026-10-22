class LugaresModel {
  final int id;
  final String nome;
  final String categoria;
  final int? categoriaId;
  final double latitude;
  final double longitude;
  final String descricao;

  const LugaresModel({
    this.id = 0,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.categoriaId,
    this.categoria = '',
    this.descricao = '',
  });

  factory LugaresModel.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    return LugaresModel(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      descricao: json['descricao'] as String? ?? '',
      categoriaId: (json['categoriaId'] as num?)?.toInt(),
      categoria: categoria is Map ? categoria['nome'] as String? ?? '' : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
    'latitude': latitude,
    'longitude': longitude,
    'categoriaId': categoriaId,
  };
}
