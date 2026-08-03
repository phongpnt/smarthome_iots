import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/model/data/topic.dart';

part 'device.g.dart';

enum DeviceType { light, air, fan, iron, other }

@JsonSerializable()
class Devices {
  String? deviceId;
  String? deviceName;
  String? createdDate;
  String? location;
  String? description;
  String? userId;
  List<Topics>? topics;
  DeviceType? type;
  bool? powerStatus;
  String? ssid;
  String? passWifi;

  Devices({
    this.deviceId,
    this.deviceName,
    this.createdDate,
    this.location,
    this.description,
    this.userId,
    this.topics,
    this.type,
    this.powerStatus,
    this.ssid,
    this.passWifi,
  });

  factory Devices.fromJson(Map<String, dynamic> json) =>
      _$DevicesFromJson(json);

  Map<String, dynamic> toJson() => _$DevicesToJson(this);

  Devices copyWith({
    String? deviceId,
    String? deviceName,
    String? createdDate,
    String? location,
    String? description,
    String? userId,
    List<Topics>? topics,
    DeviceType? type,
    bool? powerStatus,
    String? ssid,
    String? passWifi,
  }) {
    return Devices(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      createdDate: createdDate ?? this.createdDate,
      location: location ?? this.location,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      topics: topics ?? this.topics,
      type: type ?? this.type,
      powerStatus: powerStatus ?? this.powerStatus,
      ssid: ssid ?? this.ssid,
      passWifi: passWifi ?? this.passWifi,
    );
  }
}

extension DeviceExtension on DeviceType {
  String get deviceImage {
    switch (this) {
      case DeviceType.light:
        return ImagePaths.lightBulbs;
      case DeviceType.air:
        return ImagePaths.airConditioner;
      case DeviceType.fan:
        return ImagePaths.fan;
      case DeviceType.iron:
        return ImagePaths.sonofoll;
      case DeviceType.other:
        return ImagePaths.tv;
    }
  }
}
