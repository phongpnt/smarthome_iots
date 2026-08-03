import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';

class UpsertScheduleParameter {
  final Schedule? schedule;
  final Devices? devices;
  UpsertScheduleParameter({this.schedule, this.devices});
}
