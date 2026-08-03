import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:smart_home_app/src/model/data/device.dart';

part 'warning.g.dart';

@JsonSerializable()
class Warning {
  String? warningId;
  String? createdDate;
  String? warningTitle;
  String? warningContent;
  bool? newIcon;
  String? deviceId;
  String? deviceName;
  String? location;
  DeviceType? deviceType;

  String? warningSource;

  double? anomalyScore;

  Warning(
      {this.warningId,
      this.createdDate,
      this.warningTitle,
      this.warningContent,
      this.newIcon,
      this.deviceId,
      this.deviceName,
      this.location,
      this.deviceType,
      this.warningSource,
      this.anomalyScore});

  factory Warning.fromJson(Map<String, dynamic> json) =>
      _$WarningFromJson(json);

  Map<String, dynamic> toJson() => _$WarningToJson(this);

  bool get isMlAnomaly => warningSource == 'isolation_forest';
  bool get isProphet   => warningSource == 'prophet';

  Warning copyWith({
    String? warningId,
    String? createdDate,
    String? warningTitle,
    String? warningContent,
    bool? newIcon,
    String? deviceId,
    String? deviceName,
    String? location,
    DeviceType? deviceType,
    String? warningSource,
    double? anomalyScore,
  }) {
    return Warning(
      warningId: warningId ?? this.warningId,
      createdDate: createdDate ?? this.createdDate,
      warningTitle: warningTitle ?? this.warningTitle,
      warningContent: warningContent ?? this.warningContent,
      newIcon: newIcon ?? this.newIcon,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      location: location ?? this.location,
      deviceType: deviceType ?? this.deviceType,
      warningSource: warningSource ?? this.warningSource,
      anomalyScore: anomalyScore ?? this.anomalyScore,
    );
  }
}
