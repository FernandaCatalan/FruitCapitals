class Hilera {
  final String id;
  final int numero;

  Hilera({
    required this.id,
    required this.numero,
  });

  factory Hilera.fromMap(String id, Map<String, dynamic> map) {
    return Hilera(
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
