part of 'power_usage_chart.dart';

PowerUsaegChart _$PowerUsaegChartFromJson(Map<String, dynamic> json) =>
    PowerUsaegChart(
      groupDataKeyStart: json['groupDataKeyStart'] as String?,
      groupDataKeyEnd: json['groupDataKeyEnd'] as String?,
      data: (json['data'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PowerUsaegChartToJson(PowerUsaegChart instance) =>
    <String, dynamic>{
      'groupDataKeyStart': instance.groupDataKeyStart,
      'groupDataKeyEnd': instance.groupDataKeyEnd,
      'data': instance.data,
    };
