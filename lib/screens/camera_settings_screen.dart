import 'package:flutter/material.dart';
import '../models/camera_config.dart';
import '../services/camera_service.dart';

class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  final CameraService _cameraService = CameraService();
  List<CameraConfig> _cameras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    final cameras = await _cameraService.getAllCameras();
    if (cameras.isEmpty) {
      cameras.add(CameraConfig.ipWebcamHttp());
    }
    setState(() {
      _cameras = cameras;
      _isLoading = false;
    });
  }

  Future<void> _saveCameras() async {
    for (final camera in _cameras) {
      await _cameraService.saveCameraConfig(camera);
    }
  }

  void _addCamera() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CameraFormSheet(
        onSave: (camera) {
          setState(() {
            _cameras.add(camera);
          });
          _saveCameras();
        },
        presets: _getPresets(),
      ),
    );
  }

  void _editCamera(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CameraFormSheet(
        camera: _cameras[index],
        onSave: (camera) {
          setState(() {
            _cameras[index] = camera;
          });
          _saveCameras();
        },
        presets: _getPresets(),
      ),
    );
  }

  void _deleteCamera(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cámara'),
        content: const Text('¿Estás seguro de eliminar esta cámara?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cameras.removeAt(index);
              });
              _saveCameras();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _reorderCameras(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final camera = _cameras.removeAt(oldIndex);
      _cameras.insert(newIndex, camera);
    });
    _saveCameras();
  }

  List<Map<String, String>> _getPresets() {
    return [
      {'name': 'IP Webcam (HTTP)', 'type': 'http', 'port': '8080', 'path': 'videofeed'},
      {'name': 'IP Webcam (RTSP)', 'type': 'rtsp', 'port': '554', 'path': 'h264_aac.sdp'},
      {'name': 'IP Webcam (Video)', 'type': 'http', 'port': '8080', 'path': 'video'},
      {'name': 'Auto Detectar', 'type': 'auto', 'port': '8080', 'path': ''},
    ];
  }

  void _applyPreset(int index, Map<String, String> preset) {
    if (index < _cameras.length) {
      setState(() {
        _cameras[index] = _cameras[index].copyWith(
          streamType: preset['type']!,
          port: int.tryParse(preset['port']!) ?? 8080,
          streamPath: preset['path']!,
        );
      });
      _saveCameras();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "${preset['name']}" aplicado'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Cámaras'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCamera,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'IP Webcam: http://IP:8080/video o rtsp://IP:554/h264_aac.sdp',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cameras.length,
                    onReorder: _reorderCameras,
                    itemBuilder: (context, index) {
                      final camera = _cameras[index];
                      return _CameraCard(
                        key: ValueKey(camera.id),
                        camera: camera,
                        index: index,
                        presets: _getPresets(),
                        onEdit: () => _editCamera(index),
                        onDelete: () => _deleteCamera(index),
                        onApplyPreset: (preset) => _applyPreset(index, preset),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final CameraConfig camera;
  final int index;
  final List<Map<String, String>> presets;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(Map<String, String>) onApplyPreset;

  const _CameraCard({
    super.key,
    required this.camera,
    required this.index,
    required this.presets,
    required this.onEdit,
    required this.onDelete,
    required this.onApplyPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              camera.name.isNotEmpty ? camera.name : 'Cámara ${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${camera.ip}:${camera.port}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: camera.streamType == 'http' 
                        ? Colors.blue[100] 
                        : camera.streamType == 'rtsp' 
                            ? Colors.purple[100] 
                            : Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    camera.streamType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: camera.streamType == 'http' 
                          ? Colors.blue[700] 
                          : camera.streamType == 'rtsp' 
                              ? Colors.purple[700] 
                              : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return ActionChip(
                  label: Text(preset['name']!, style: const TextStyle(fontSize: 12)),
                  onPressed: () => onApplyPreset(preset),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraFormSheet extends StatefulWidget {
  final CameraConfig? camera;
  final Function(CameraConfig) onSave;
  final List<Map<String, String>> presets;

  const _CameraFormSheet({
    this.camera,
    required this.onSave,
    required this.presets,
  });

  @override
  State<_CameraFormSheet> createState() => _CameraFormSheetState();
}

class _CameraFormSheetState extends State<_CameraFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _streamPathController;
  late String _streamType;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camera?.name ?? '');
    _ipController = TextEditingController(text: widget.camera?.ip ?? '');
    _portController = TextEditingController(text: widget.camera?.port.toString() ?? '8080');
    _usernameController = TextEditingController(text: widget.camera?.username ?? '');
    _passwordController = TextEditingController(text: widget.camera?.password ?? '');
    _streamPathController = TextEditingController(text: widget.camera?.streamPath ?? 'video');
    _streamType = widget.camera?.streamType ?? 'http';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _streamPathController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, String> preset) {
    setState(() {
      _streamType = preset['type']!;
      _portController.text = preset['port']!;
      _streamPathController.text = preset['path'] ?? '';
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final config = CameraConfig(
      id: widget.camera?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      ip: _ipController.text.trim(),
      port: int.parse(_portController.text.trim()),
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      streamPath: _streamPathController.text.trim(),
      streamType: _streamType,
    );

    widget.onSave(config);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.camera == null ? 'Agregar Cámara' : 'Editar Cámara',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _streamType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Stream',
                  prefixIcon: const Icon(Icons.stream),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('Auto Detectar')),
                  DropdownMenuItem(value: 'http', child: Text('HTTP MJPEG')),
                  DropdownMenuItem(value: 'rtsp', child: Text('RTSP (Mejor calidad)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _streamType = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final preset in widget.presets.take(2))
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => _applyPreset(preset),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            preset['name']!,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre (ej: Cámara Laboratorio)',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ipController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Dirección IP',
                  hintText: 'Ej: 192.168.15.11',
                  prefixIcon: const Icon(Icons.router),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la IP';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Puerto',
                        hintText: _streamType == 'rtsp' ? '554' : '8080',
                        prefixIcon: const Icon(Icons.settings_ethernet),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Puerto';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _streamPathController,
                      decoration: InputDecoration(
                        labelText: 'Path',
                        hintText: _streamType == 'rtsp' ? 'h264_aac.sdp' : 'video',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Usuario (opcional)',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña (opcional)',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.camera == null ? 'Agregar' : 'Guardar Cambios',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}