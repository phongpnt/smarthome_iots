part of 'device.dart';

Devices _$DevicesFromJson(Map<String, dynamic> json) => Devices(
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      createdDate: json['createdDate'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      userId: json['userId'] as String?,
      topics: (json['topics'] as List<dynamic>?)
          ?.map((e) => Topics.fromJson(e as Map<String, dynamic>))
          .toList(),
      type: $enumDecodeNullable(_$DeviceTypeEnumMap, json['type']),
      powerStatus: json['powerStatus'] as bool?,
      ssid: json['ssid'] as String?,
      passWifi: json['passWifi'] as String?,
    );

Map<String, dynamic> _$DevicesToJson(Devices instance) => <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'createdDate': instance.createdDate,
      'location': instance.location,
      'description': instance.description,
      'userId': instance.userId,
      'topics': instance.topics,
      'type': _$DeviceTypeEnumMap[instance.type],
      'powerStatus': instance.powerStatus,
      'ssid': instance.ssid,
      'passWifi': instance.passWifi,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.light: 'light',
  DeviceType.air: 'air',
  DeviceType.fan: 'fan',
  DeviceType.iron: 'iron',
  DeviceType.other: 'other',
};
