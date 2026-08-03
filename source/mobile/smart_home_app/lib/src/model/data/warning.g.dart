part of 'warning.dart';

Warning _$WarningFromJson(Map<String, dynamic> json) => Warning(
      warningId: json['warningId'] as String?,
      createdDate: json['createdDate'] as String?,
      warningTitle: json['warningTitle'] as String?,
      warningContent: json['warningContent'] as String?,
      newIcon: json['newIcon'] as bool?,
      deviceId: json['deviceId'] as String?,
      deviceName: json['deviceName'] as String?,
      location: json['location'] as String?,
      deviceType: $enumDecodeNullable(_$DeviceTypeEnumMap, json['deviceType']),
      warningSource: json['warningSource'] as String?,
      anomalyScore: (json['anomalyScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$WarningToJson(Warning instance) => <String, dynamic>{
      'warningId': instance.warningId,
      'createdDate': instance.createdDate,
      'warningTitle': instance.warningTitle,
      'warningContent': instance.warningContent,
      'newIcon': instance.newIcon,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'location': instance.location,
      'deviceType': _$DeviceTypeEnumMap[instance.deviceType],
      'warningSource': instance.warningSource,
      'anomalyScore': instance.anomalyScore,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.light: 'light',
  DeviceType.air: 'air',
  DeviceType.fan: 'fan',
  DeviceType.iron: 'iron',
  DeviceType.other: 'other',
};
