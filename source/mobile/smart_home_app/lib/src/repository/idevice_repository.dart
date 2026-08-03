import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';

abstract class IDeviceResponsitory {
  Future<List<Devices>> getDevices();
  Future<void> updateDevices(Devices devices);
  Future<List<Schedule>> getListSchedules();
  Future<void> updateSchedule(Schedule schedule);
  Future<List<Schedule>> getListSchedulesByDevice(String deviceId);
  Future<List<PowerUsage>> getListPowerUsage();
  Future<List<PowerUsage>> getPowerUsageByRange(String userId, DateTime from, DateTime to);
  Future<Schedule?> onAddSchedule(Schedule schedule);
  Future<void> onUpdateSchedule(Schedule schedule);
  Future<Devices?> onAddDevice(Devices devices);
  Future<void> onUpdateDevice(Devices devices);
  Future<void> deleteSchedule(String id);
}
