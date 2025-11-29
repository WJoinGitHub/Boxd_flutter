class DeviceModel {
  final int id;
  final String userId;
  final String deviceUuid;
  final String deviceName;
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
    required this.isPrimary,
    required this.bindOrder,
    required this.status,
    required this.bindTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      deviceUuid: json['device_uuid'] ?? '',
      deviceName: json['device_name'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      bindOrder: json['bind_order'] ?? 0,
      status: json['status'] ?? '',
      bindTime: json['bind_time'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
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
}
