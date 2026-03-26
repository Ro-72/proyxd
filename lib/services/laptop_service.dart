import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/laptop.dart';
import '../models/laptop_record.dart';

class LaptopService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, Laptop> _laptops = {};

  Future<void> loadLaptops() async {
    final String response = await rootBundle.loadString('assets/laptops.json');
    final data = await json.decode(response);

    _laptops = {};
    final laptopsData = data['laptops'] as Map<String, dynamic>;
    laptopsData.forEach((key, value) {
      _laptops[key] = Laptop.fromJson(key, value);
    });
  }

  Laptop? getLaptopById(String id) {
    return _laptops[id];
  }

  Stream<List<LaptopRecord>> getRecordsStream() {
    return _database.child('usersTest').onValue.map((event) {
      final List<LaptopRecord> records = [];

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Cada clave (ej: 6831) es una instancia que contiene directamente los campos
        data.forEach((instanceId, recordData) {
          if (recordData is Map) {
            final recordMap = Map<String, dynamic>.from(recordData);
            // Verificar que tenga los campos necesarios (uid, fecha, timestamp, status)
            if (recordMap.containsKey('uid') &&
                recordMap.containsKey('fecha') &&
                recordMap.containsKey('timestamp') &&
                recordMap.containsKey('status')) {
              records.add(
                LaptopRecord.fromJson(
                  instanceId.toString(),  // El ID del registro es el número aleatorio
                  instanceId.toString(),  // instanceId también es el número aleatorio
                  recordMap,
                ),
              );
            }
          }
        });
      }

      // Ordenar por fecha y hora descendente (más reciente primero)
      records.sort((a, b) {
        final dateTimeA = a.getDateTime();
        final dateTimeB = b.getDateTime();

        if (dateTimeA == null && dateTimeB == null) return 0;
        if (dateTimeA == null) return 1;
        if (dateTimeB == null) return -1;

        return dateTimeB.compareTo(dateTimeA);
      });

      return records;
    });
  }

  Future<List<LaptopRecord>> getRecordsByDate(DateTime date) async {
    final snapshot = await _database.child('usersTest').get();
    final List<LaptopRecord> records = [];

    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;

      // Cada clave (ej: 6831) es una instancia que contiene directamente los campos
      data.forEach((instanceId, recordData) {
        if (recordData is Map) {
          final recordMap = Map<String, dynamic>.from(recordData);
          // Verificar que tenga los campos necesarios
          if (recordMap.containsKey('uid') &&
              recordMap.containsKey('fecha') &&
              recordMap.containsKey('timestamp') &&
              recordMap.containsKey('status')) {
            final record = LaptopRecord.fromJson(
              instanceId.toString(),  // El ID del registro es el número aleatorio
              instanceId.toString(),  // instanceId también es el número aleatorio
              recordMap,
            );

            // Filtrar por fecha
            if (record.isFromDate(date)) {
              records.add(record);
            }
          }
        }
      });
    }

    // Ordenar por fecha y hora descendente
    records.sort((a, b) {
      final dateTimeA = a.getDateTime();
      final dateTimeB = b.getDateTime();

      if (dateTimeA == null && dateTimeB == null) return 0;
      if (dateTimeA == null) return 1;
      if (dateTimeB == null) return -1;

      return dateTimeB.compareTo(dateTimeA);
    });

    return records;
  }
}
