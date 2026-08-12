import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/camera_service.dart';
import '../services/activation_service.dart';
import '../models/laptop_record.dart';
import '../models/camera_config.dart';
import 'camera_settings_screen.dart';

class CameraScreen extends StatefulWidget {
  final LaptopRecord? initialRecord;

  const CameraScreen({super.key, this.initialRecord});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final ActivationService _activationService = ActivationService();

  WebViewController? _webViewController;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _streamUrl = '';
  String _webViewUrl = '';
  LaptopRecord? _currentRecord;
  String _connectionStatus = 'Conectando...';
  String _streamType = 'http';
  int _selectedCameraIndex = 0;
  List<CameraConfig> _cameras = [];

  double _zoomLevel = 1.0;
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;

  bool _cameraForcedActive = false;

  @override
  void initState() {
    super.initState();
    _currentRecord = widget.initialRecord;
    _initializeCameras();
    _startMonitoring();
  }

  Future<void> _initializeCameras() async {
    final cameras = await _cameraService.getAllCameras();

    if (cameras.isEmpty) {
      cameras.add(CameraConfig.ipWebcamHttp());
    }

    setState(() {
      _cameras = cameras;
    });

    if (cameras.isNotEmpty) {
      final camera = cameras[_selectedCameraIndex];
      if (!camera.isConfigured) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Configura la IP de la cámara en ajustes';
          _connectionStatus = 'Error';
          _isLoading = false;
        });
        return;
      }
      _connectToCamera(camera);
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _buildWebViewUrl(CameraConfig config) {
    if (config.streamType == 'http' || config.streamType == 'rtsp') {
      final credentials = config.username.isNotEmpty
          ? '${config.username}:${config.password}@'
          : '';
      final path = config.streamPath.isNotEmpty ? '/${config.streamPath}' : '/videofeed';
      return 'http://$credentials${config.ip}:${config.port}$path';
    }
    return '';
  }

  void _connectToCamera(CameraConfig config) {
    _webViewController = null;
    _zoomLevel = 1.0;

    setState(() {
      _hasError = false;
      _streamUrl = config.getUrl();
      _webViewUrl = _buildWebViewUrl(config);
      _streamType = config.streamType;
      _connectionStatus = 'Conectando...';
      _isLoading = true;
    });

    if (_streamType == 'http') {
      _initializeWebView();
    } else {
      _openInVlcApp();
    }
  }

  void _initializeWebView() {
    if (_webViewUrl.isEmpty) {
      _handleConnectionError('URL de cámara está vacía');
      return;
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _connectionStatus = 'Cargando...';
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _connectionStatus = 'En vivo';
            });
          },
          onWebResourceError: (WebResourceError error) {
            _handleConnectionError('Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_webViewUrl));

    setState(() {});
  }

  void _handleConnectionError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _connectionStatus = 'Error';
        _isLoading = false;
      });
    }
  }

  void _zoomIn() {
    if (_zoomLevel < _maxZoom) {
      setState(() {
        _zoomLevel += 0.25;
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > _minZoom) {
      setState(() {
        _zoomLevel -= 0.25;
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _startMonitoring() {
    _activationService.startMonitoring();
    _activationService.activationStream.listen((record) {
      if (record.status == 'Activo' && mounted) {
        setState(() => _currentRecord = record);
        _activateCameraFor45Seconds();
        _showActivationNotification(record);
      }
    });
  }

  void _activateCameraFor45Seconds() {
    _cameraForcedActive = true;
    if (_cameras.isNotEmpty) {
      _connectToCamera(_cameras[_selectedCameraIndex]);
    }
    
    Future.delayed(const Duration(seconds: 45), () {
      if (mounted) {
        setState(() {
          _cameraForcedActive = false;
        });
      }
    });
  }

  void _showActivationNotification(LaptopRecord record) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.videocam, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Detección activa!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Laptop: ${record.uid} - ${record.timestamp}'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _openInVlcApp() async {
    if (_streamUrl.isEmpty) return;

    setState(() {
      _connectionStatus = 'Abriendo VLC...';
      _isLoading = false;
    });

    final uri = Uri.parse(_streamUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() {
        _connectionStatus = 'En vivo (VLC)';
      });
    } else {
      _handleConnectionError('No se pudo abrir VLC. Instala VLC desde Play Store.');
    }
  }

  Future<void> _openInExternalApp() async {
    await _openInVlcApp();
  }

  Future<void> _reconnect() async {
    if (_cameras.isNotEmpty) {
      _connectToCamera(_cameras[_selectedCameraIndex]);
    }
  }

  void _switchCamera(int index) {
    if (index != _selectedCameraIndex && index < _cameras.length) {
      setState(() {
        _selectedCameraIndex = index;
      });
      _connectToCamera(_cameras[index]);
    }
  }

  @override
  void dispose() {
    _activationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara de Seguridad'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _streamUrl.isNotEmpty ? _openInExternalApp : null,
            tooltip: 'Abrir en VLC',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraSettingsScreen(),
                ),
              );
              _initializeCameras();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reconnect,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_cameras.length > 1) _buildCameraSelector(),
          _buildStatusBar(),
          Expanded(
            child: _buildVideoArea(),
          ),
          if (_currentRecord != null) _buildRecordInfo(),
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraSelector() {
    return Container(
      height: 50,
      color: Colors.grey[200],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cameras.length,
        itemBuilder: (context, index) {
          final camera = _cameras[index];
          final isSelected = index == _selectedCameraIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(camera.name.isNotEmpty ? camera.name : 'Cámara ${index + 1}'),
              selected: isSelected,
              onSelected: (_) => _switchCamera(index),
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    Color statusColor;
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'En vivo':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        break;
      case 'Error':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      case 'Conectando...':
      case 'Cargando...':
      case 'Abriendo VLC...':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _connectionStatus,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _streamType == 'http' ? Colors.blue[100] : Colors.purple[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _streamType.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _streamType == 'http' ? Colors.blue[700] : Colors.purple[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_currentRecord != null) ...[
            Icon(Icons.notifications_active, color: Colors.green[700], size: 16),
            const SizedBox(width: 4),
            Text(
              'Registro: ${_currentRecord!.uid}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (_hasError) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off, size: 80, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Error de conexión',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      if (_webViewUrl.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'URL: $_webViewUrl',
                          style: TextStyle(
                            color: Colors.red[500],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _reconnect,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_streamType == 'http' && _webViewController != null) {
      return SizedBox.expand(
        child: WebViewWidget(controller: _webViewController!),
      );
    }

    if (_streamType == 'rtsp') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _connectionStatus == 'En vivo (VLC)' ? Icons.play_circle_filled : Icons.videocam,
              size: 80,
              color: _connectionStatus == 'En vivo (VLC)' ? Colors.green : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _connectionStatus == 'En vivo (VLC)' ? 'Reproduciendo en VLC' : 'Abriendo VLC...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El stream debería abrirse en la app VLC',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_streamUrl.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _streamUrl,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _openInVlcApp,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir en VLC'),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Esperando conexión...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (_webViewUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openInExternalApp,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en VLC'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    if (_streamType != 'http') return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _zoomOut,
            icon: const Icon(Icons.zoom_out),
            iconSize: 36,
            color: Theme.of(context).primaryColor,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: _zoomIn,
            icon: const Icon(Icons.zoom_in),
            iconSize: 36,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _resetZoom,
            icon: const Icon(Icons.refresh),
            iconSize: 36,
            color: Colors.grey[600],
            tooltip: 'Reset zoom',
          ),
        ],
      ),
    );
  }

  Widget _buildRecordInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Última detección:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Laptop: ${_currentRecord!.uid}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                Text(
                  '${_currentRecord!.fecha} - ${_currentRecord!.timestamp}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}