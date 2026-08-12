class CameraConfig {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String username;
  final String password;
  final String streamPath;
  final String streamType;

  CameraConfig({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    this.username = '',
    this.password = '',
    this.streamPath = '',
    this.streamType = 'auto',
  });

  factory CameraConfig.ipWebcamHttp({
    String name = 'IP Webcam',
    String ip = '',
    int port = 8080,
    String streamPath = 'videofeed',
  }) => CameraConfig(
    id: 'ipwebcam_http',
    name: name,
    ip: ip,
    port: port,
    streamPath: streamPath,
    streamType: 'http',
  );

  factory CameraConfig.ipWebcamRtsp({
    String name = 'IP Webcam RTSP',
    String ip = '',
    int port = 554,
    String streamPath = 'h264_aac.sdp',
  }) => CameraConfig(
    id: 'ipwebcam_rtsp',
    name: name,
    ip: ip,
    port: port,
    streamPath: streamPath,
    streamType: 'rtsp',
  );

  factory CameraConfig.autoDetect({
    String name = 'Auto Detectar',
    String ip = '',
    int port = 8080,
  }) => CameraConfig(
    id: 'auto',
    name: name,
    ip: ip,
    port: port,
    streamType: 'auto',
  );

  String get rtspUrl {
    final credentials = username.isNotEmpty ? '$username:$password@' : '';
    final path = streamPath.isNotEmpty ? '/$streamPath' : '';
    return 'rtsp://$credentials$ip:$port$path';
  }

  String get httpUrl {
    final credentials = username.isNotEmpty ? '$username:$password@' : '';
    final path = streamPath.isNotEmpty ? '/$streamPath' : '/videofeed';
    return 'http://$credentials$ip:$port$path';
  }

  String getUrl() {
    if (streamType == 'http') {
      return httpUrl;
    } else if (streamType == 'rtsp') {
      return rtspUrl;
    }
    return httpUrl;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'username': username,
        'password': password,
        'streamPath': streamPath,
        'streamType': streamType,
      };

  factory CameraConfig.fromJson(Map<String, dynamic> json) => CameraConfig(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        ip: json['ip'] ?? '',
        port: json['port'] ?? 554,
        username: json['username'] ?? '',
        password: json['password'] ?? '',
        streamPath: json['streamPath'] ?? '',
        streamType: json['streamType'] ?? 'auto',
      );

  bool get isConfigured => ip.isNotEmpty && port > 0;

  CameraConfig copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    String? username,
    String? password,
    String? streamPath,
    String? streamType,
  }) =>
      CameraConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        ip: ip ?? this.ip,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        streamPath: streamPath ?? this.streamPath,
        streamType: streamType ?? this.streamType,
      );
}