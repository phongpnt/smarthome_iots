import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:smart_home_app/src/model/data/device.dart';

part 'schedule.g.dart';

@JsonSerializable()
class Schedule {
  String? id;
  String? dayOfWeek;
  String? time;
  bool? powerStatus;
  bool? active;
  String? description;
  String? deviceId;
  @JsonKey(includeToJson: false)
  String? deviceName;
  @JsonKey(includeToJson: false)
  String? createdDate;
  @JsonKey(includeToJson: false)
  String? location;
  @JsonKey(includeToJson: false)
  String? deviceDescription;
  @JsonKey(includeToJson: false)
  bool? devicePowerStatus;
  @JsonKey(includeToJson: false)
  String? userId;
  @JsonKey(includeToJson: false)
  DeviceType? type;
  @JsonKey(ignore: true)
  Devices? devices;

  Schedule({
    this.id,
    this.dayOfWeek,
    this.time,
    this.devices,
    this.powerStatus,
    this.active,
    this.description,
    this.deviceId,
    this.deviceName,
    this.createdDate,
    this.location,
    this.deviceDescription,
    this.devicePowerStatus,
    this.userId,
    this.type,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleToJson(this);

  Schedule copyWith({
    String? id,
    String? dayOfWeek,
    String? time,
    bool? powerStatus,
    bool? active,
    String? description,
    String? deviceId,
    String? deviceName,
    String? createdDate,
    String? location,
    String? deviceDescription,
    bool? devicePowerStatus,
    String? userId,
    DeviceType? type,
    Devices? devices,
  }) {
    return Schedule(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      time: time ?? this.time,
      powerStatus: powerStatus ?? this.powerStatus,
      active: active ?? this.active,
      description: description ?? this.description,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      createdDate: createdDate ?? this.createdDate,
      location: location ?? this.location,
      deviceDescription: deviceDescription ?? this.deviceDescription,
      devicePowerStatus: devicePowerStatus ?? this.devicePowerStatus,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      devices: devices ?? this.devices,
    );
  }
}

extension ScheduleExtension on Schedule {
  String get dayText {
    var text = '';
    final day = dayOfWeek ?? '';
    if (day.contains('1') &&
        day.contains('2') &&
        day.contains('3') &&
        day.contains('4') &&
        day.contains('5') &&
        day.contains('7') &&
        day.contains('6')) {
      return 'All week';
    }
    final split = dayOfWeek?.split('') ?? [];
    if (split.isEmpty) {
      return '';
    }
    for (final val in split) {
      final newVal = _getDayOfWeekText(val);
      if (newVal.isNotEmpty) {
        text += '$newVal ';
      }
    }

    return text;
  }

  String _getDayOfWeekText(String index) {
    switch (index) {
      case '1':
        return 'Mon';
      case '2':
        return 'Tue';
      case '3':
        return 'Web';
      case '4':
        return 'Thurs';
      case '5':
        return 'Fri';
      case '6':
        return 'Sat';
      case '7':
        return 'Sun';
    }
    return '';
  }
}
