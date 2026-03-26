class LaptopRecord {
  final String id;
  final String instanceId; // Número aleatorio de la instancia
  final String uid; // ID de la laptop
  final String fecha; // Fecha del registro
  final String status; // Estado del registro
  final String timestamp; // Hora del registro
  final String? usuario;
  final String? observaciones;

  LaptopRecord({
    required this.id,
    required this.instanceId,
    required this.uid,
    required this.fecha,
    required this.status,
    required this.timestamp,
    this.usuario,
    this.observaciones,
  });

  factory LaptopRecord.fromJson(String id, String instanceId, Map<String, dynamic> json) {
    return LaptopRecord(
      id: id,
      instanceId: instanceId,
      uid: json['uid'] ?? '',
      fecha: json['fecha'] ?? '',
      status: json['status'] ?? '',
      timestamp: json['timestamp'] ?? '',
      usuario: json['usuario'],
      observaciones: json['observaciones'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fecha': fecha,
      'status': status,
      'timestamp': timestamp,
      'usuario': usuario,
      'observaciones': observaciones,
    };
  }

  // Parsea la fecha en formato DD/MM/YYYY a DateTime
  DateTime? getParsedDate() {
    try {
      final parts = fecha.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String getFormattedDate() {
    return fecha;
  }

  String getFormattedTime() {
    return timestamp;
  }

  // Compara si este registro es del día especificado
  bool isFromDate(DateTime date) {
    final parsedDate = getParsedDate();
    if (parsedDate == null) return false;

    return parsedDate.year == date.year &&
           parsedDate.month == date.month &&
           parsedDate.day == date.day;
  }

  // Para ordenar por fecha y hora
  DateTime? getDateTime() {
    final parsedDate = getParsedDate();
    if (parsedDate == null) return null;

    try {
      final timeParts = timestamp.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          hour,
          minute,
        );
      }
    } catch (e) {
      return parsedDate;
    }
    return parsedDate;
  }
}
