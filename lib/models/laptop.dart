class Laptop {
  final String id;
  final String nombre;
  final String laboratorio;

  Laptop({
    required this.id,
    required this.nombre,
    required this.laboratorio,
  });

  factory Laptop.fromJson(String id, Map<String, dynamic> json) {
    return Laptop(
      id: id,
      nombre: json['nombre'] ?? '',
      laboratorio: json['laboratorio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'laboratorio': laboratorio,
    };
  }
}
