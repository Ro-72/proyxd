import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/laptop_record.dart';
import '../services/laptop_service.dart';
import '../widgets/laptop_record_card.dart';
import 'camera_screen.dart';

class LaptopRecordsScreen extends StatefulWidget {
  const LaptopRecordsScreen({super.key});

  @override
  State<LaptopRecordsScreen> createState() => _LaptopRecordsScreenState();
}

class _LaptopRecordsScreenState extends State<LaptopRecordsScreen> {
  final LaptopService _laptopService = LaptopService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showAll = true;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  StreamSubscription<List<LaptopRecord>>? _recordsSubscription;
  Set<String> _knownRecordIds = {};
  LaptopRecord? _newActiveRecord;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initRecordsListener();
  }

  Future<void> _initializeService() async {
    await _laptopService.loadLaptops();
    setState(() {
      _isLoading = false;
    });
  }

  void _initRecordsListener() {
    _recordsSubscription = _laptopService.getRecordsStream().listen((records) {
      final newActiveRecords = records.where((r) =>
        !_knownRecordIds.contains(r.id)
      ).toList();

      if (newActiveRecords.isNotEmpty && mounted) {
        final newest = newActiveRecords.first;
        setState(() {
          _newActiveRecord = newest;
          _showBanner = true;
          _knownRecordIds.add(newest.id);
        });
        _scheduleBannerDismiss();
      }

      _knownRecordIds = records.map((r) => r.id).toSet();
    });
  }

  void _scheduleBannerDismiss() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showBanner = false);
      }
    });
  }

  void _dismissBanner() {
    setState(() => _showBanner = false);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _showAll = false;
      });
    }
  }

  void _showAllRecords() {
    setState(() {
      _showAll = true;
      _selectedDay = null;
    });
  }

  @override
  void dispose() {
    _recordsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registros de Salida de Laptops',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 4,
                      child: Column(
                        children: [
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            calendarFormat: _calendarFormat,
                            selectedDayPredicate: (day) {
                              return isSameDay(_selectedDay, day);
                            },
                            onDaySelected: _onDaySelected,
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            calendarStyle: CalendarStyle(
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: const TextStyle(color: Colors.white),
                              todayTextStyle: const TextStyle(color: Colors.white),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showAllRecords,
                                icon: const Icon(Icons.list),
                                label: const Text('Mostrar Todos los Registros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _showAll
                                  ? 'Mostrando todos los registros'
                                  : 'Mostrando registros del ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CameraScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.videocam),
                          label: const Text('Ver Cámara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildRecordsList(),
                    ),
                  ],
                ),
          if (_showBanner && _newActiveRecord != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildDetectionBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetectionBanner() {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _showBanner ? Offset.zero : const Offset(0, -1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _showBanner ? 1.0 : 0.0,
        child: Material(
          elevation: 6,
          color: Colors.green[700],
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡Dispositivo Detectado!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Laptop: ${_newActiveRecord!.uid} - ${_newActiveRecord!.timestamp}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _dismissBanner();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            initialRecord: _newActiveRecord,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Ver Cámara'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _dismissBanner,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    if (_showAll) {
      return StreamBuilder<List<LaptopRecord>>(
        stream: _laptopService.getRecordsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar registros',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros disponibles',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final laptop = _laptopService.getLaptopById(record.uid);
              return LaptopRecordCard(
                record: record,
                laptop: laptop,
              );
            },
          );
        },
      );
    } else {
      return FutureBuilder<List<LaptopRecord>>(
        future: _laptopService.getRecordsByDate(_selectedDay!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar registros',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay registros para esta fecha',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final laptop = _laptopService.getLaptopById(record.uid);
              return LaptopRecordCard(
                record: record,
                laptop: laptop,
              );
            },
          );
        },
      );
    }
  }
}
