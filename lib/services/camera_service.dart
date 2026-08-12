import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camera_config.dart';

class CameraService {
  static const String _cameraConfigKey = 'camera_configs';

  Future<List<CameraConfig>> getAllCameras() async {
    final prefs = await SharedPreferences.getInstance();
    final configString = prefs.getString(_cameraConfigKey);

    if (configString == null) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(configString);
      return jsonList
          .map((json) => CameraConfig.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<CameraConfig> getCameraConfig() async {
    final cameras = await getAllCameras();
    if (cameras.isEmpty) {
      return CameraConfig.ipWebcamHttp();
    }
    return cameras.first;
  }

  Future<void> saveCameraConfig(CameraConfig config) async {
    final cameras = await getAllCameras();
    
    final existingIndex = cameras.indexWhere((c) => c.id == config.id);
    if (existingIndex >= 0) {
      cameras[existingIndex] = config;
    } else {
      cameras.add(config);
    }
    
    await _saveCameras(cameras);
  }

  Future<void> addCamera(CameraConfig config) async {
    final cameras = await getAllCameras();
    cameras.add(config);
    await _saveCameras(cameras);
  }

  Future<void> updateCamera(CameraConfig config) async {
    final cameras = await getAllCameras();
    final index = cameras.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      cameras[index] = config;
      await _saveCameras(cameras);
    }
  }

  Future<void> deleteCamera(String id) async {
    final cameras = await getAllCameras();
    cameras.removeWhere((c) => c.id == id);
    await _saveCameras(cameras);
  }

  Future<void> reorderCameras(int oldIndex, int newIndex) async {
    final cameras = await getAllCameras();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final camera = cameras.removeAt(oldIndex);
    cameras.insert(newIndex, camera);
    await _saveCameras(cameras);
  }

  Future<void> _saveCameras(List<CameraConfig> cameras) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = cameras.map((c) => c.toJson()).toList();
    await prefs.setString(_cameraConfigKey, jsonEncode(jsonList));
  }

  Future<bool> isCameraConfigured() async {
    final cameras = await getAllCameras();
    return cameras.any((c) => c.isConfigured);
  }

  Future<String> getRtspUrl() async {
    final config = await getCameraConfig();
    return config.getUrl();
  }
}