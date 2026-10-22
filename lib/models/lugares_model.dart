class LugaresModel {
  final int id;
  final String nome;
  final String? categoria;
  final double latitude;
  final double longitude;
  final String? descricao;

  LugaresModel({
    required this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.categoria = '',
    this.descricao = '',
  });

  // Converter dados JSON da API para objeto
  factory LugaresModel.fromJson(Map<String, dynamic> json) {
    return LugaresModel(
      id: json['id'],
      nome: json['nome'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      descricao: json['descricao'],
      categoria: json['categoria']?['nome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'descricao': descricao,
      'categoria': categoria,
    };
  }
}