import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smart_home_app/src/model/data/device.dart';

part 'power_usage.g.dart';

@JsonSerializable()
class PowerUsage {
  String? logId;
  String? calculateDate;
  String? startDate;
  String? endDate;
  double? powerUsageWat;
  String? deviceId;
  @JsonKey(ignore: true)
  Devices? devices;

  PowerUsage(
      {this.logId,
      this.calculateDate,
      this.startDate,
      this.endDate,
      this.powerUsageWat,
      this.devices,
      this.deviceId});

  factory PowerUsage.fromJson(Map<String, dynamic> json) =>
      _$PowerUsageFromJson(json);

  Map<String, dynamic> toJson() => _$PowerUsageToJson(this);

  PowerUsage copyWith({
    String? logId,
    String? calculateDate,
    String? startDate,
    String? endDate,
    double? powerUsageWat,
    String? deviceId,
    Devices? devices,
  }) {
    return PowerUsage(
      logId: logId ?? this.logId,
      calculateDate: calculateDate ?? this.calculateDate,
      startDate: endDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      powerUsageWat: powerUsageWat ?? this.powerUsageWat,
      deviceId: deviceId ?? this.deviceId,
      devices: devices ?? this.devices,
    );
  }
}
