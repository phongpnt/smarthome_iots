part of 'power_usage.dart';

PowerUsage _$PowerUsageFromJson(Map<String, dynamic> json) => PowerUsage(
      logId: json['logId'] as String?,
      calculateDate: json['calculateDate'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      powerUsageWat: (json['powerUsageWat'] as num?)?.toDouble(),
      deviceId: json['deviceId'] as String?,
    );

Map<String, dynamic> _$PowerUsageToJson(PowerUsage instance) =>
    <String, dynamic>{
      'logId': instance.logId,
      'calculateDate': instance.calculateDate,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'powerUsageWat': instance.powerUsageWat,
      'deviceId': instance.deviceId,
    };
