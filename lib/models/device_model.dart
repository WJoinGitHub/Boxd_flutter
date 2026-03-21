/// 绑定设备（设备列表接口 + 本地缓存显示名）
class DeviceModel {
  final int id;
  final String userId;
  final String deviceUuid;
  final String deviceName;

  /// 本地修改的显示名，非接口字段
  final String? localName;
  final bool isPrimary;
  final int bindOrder;
  final String status;
  final String bindTime;
  final String createdAt;
  final String updatedAt;

  DeviceModel({
    required this.id,
    required this.userId,
    required this.deviceUuid,
    required this.deviceName,
    this.localName,
    required this.isPrimary,
    required this.bindOrder,
    required this.status,
    required this.bindTime,
    required this.createdAt,
    required this.updatedAt,
  });

  String listDisplayName({String fallback = 'Unknown Device'}) {
    final l = localName?.trim();
    if (l != null && l.isNotEmpty) return l;
    final s = deviceName.trim();
    if (s.isNotEmpty) return s;
    return fallback;
  }

  String headerDisplayName({String fallback = 'HeatLink'}) {
    final l = localName?.trim();
    if (l != null && l.isNotEmpty) return l;
    final s = deviceName.trim();
    if (s.isNotEmpty) return s;
    return fallback;
  }

  factory DeviceModel.fromJson(Map<String, dynamic> json, {String? localName}) {
    return DeviceModel(
      id: _readInt(json['id']),
      userId: json['user_id']?.toString() ?? '',
      deviceUuid: json['device_uuid']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? '',
      localName: localName,
      isPrimary: json['is_primary'] == true,
      bindOrder: _readInt(json['bind_order']),
      status: json['status']?.toString() ?? '',
      bindTime: json['bind_time']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_uuid': deviceUuid,
      'device_name': deviceName,
      'is_primary': isPrimary,
      'bind_order': bindOrder,
      'status': status,
      'bind_time': bindTime,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DeviceModel copyWith({
    int? id,
    String? userId,
    String? deviceUuid,
    String? deviceName,
    String? localName,
    bool? isPrimary,
    int? bindOrder,
    String? status,
    String? bindTime,
    String? createdAt,
    String? updatedAt,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      deviceName: deviceName ?? this.deviceName,
      localName: localName ?? this.localName,
      isPrimary: isPrimary ?? this.isPrimary,
      bindOrder: bindOrder ?? this.bindOrder,
      status: status ?? this.status,
      bindTime: bindTime ?? this.bindTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceModel &&
          runtimeType == other.runtimeType &&
          deviceUuid == other.deviceUuid;

  @override
  int get hashCode => deviceUuid.hashCode;
}
