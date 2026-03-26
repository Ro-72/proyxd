import 'package:flutter/material.dart';
import '../models/laptop_record.dart';
import '../models/laptop.dart';

class LaptopRecordCard extends StatefulWidget {
  final LaptopRecord record;
  final Laptop? laptop;

  const LaptopRecordCard({
    super.key,
    required this.record,
    this.laptop,
  });

  @override
  State<LaptopRecordCard> createState() => _LaptopRecordCardState();
}

class _LaptopRecordCardState extends State<LaptopRecordCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.laptop, color: Colors.white),
            ),
            title: Text(
              widget.laptop?.nombre ?? 'Laptop ID: ${widget.record.uid}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${widget.record.getFormattedDate()} - ${widget.record.getFormattedTime()}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          ),
          if (_isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'ID de Instancia',
                    widget.record.instanceId,
                    Icons.fingerprint,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Código Laptop (UID)',
                    widget.record.uid,
                    Icons.tag,
                  ),
                  const SizedBox(height: 12),
                  if (widget.laptop != null) ...[
                    _buildDetailRow(
                      'Nombre',
                      widget.laptop!.nombre,
                      Icons.laptop_mac,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Laboratorio',
                      widget.laptop!.laboratorio,
                      Icons.location_on,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildDetailRow(
                    'Fecha',
                    widget.record.getFormattedDate(),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Hora (Timestamp)',
                    widget.record.getFormattedTime(),
                    Icons.access_time,
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow(
                    'Estado',
                    widget.record.status,
                    Icons.info,
                  ),
                  if (widget.record.usuario != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Usuario',
                      widget.record.usuario!,
                      Icons.person,
                    ),
                  ],
                  if (widget.record.observaciones != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      'Observaciones',
                      widget.record.observaciones!,
                      Icons.notes,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon) {
    // Determinar el color según el estado
    Color statusColor;
    Color statusBgColor;

    switch (value.toLowerCase()) {
      case 'activo':
      case 'active':
      case 'en uso':
        statusColor = Colors.green[700]!;
        statusBgColor = Colors.green[50]!;
        break;
      case 'inactivo':
      case 'inactive':
      case 'devuelto':
        statusColor = Colors.grey[700]!;
        statusBgColor = Colors.grey[50]!;
        break;
      case 'pendiente':
      case 'pending':
        statusColor = Colors.orange[700]!;
        statusBgColor = Colors.orange[50]!;
        break;
      default:
        statusColor = Colors.blue[700]!;
        statusBgColor = Colors.blue[50]!;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
