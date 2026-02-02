class Mata {
  final String id;
  final int numero;

  Mata({
    required this.id,
    required this.numero,
  });

  factory Mata.fromMap(String id, Map<String, dynamic> map) {
    return Mata(
      id: id,
      numero: (map['numero'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
    };
  }
}
