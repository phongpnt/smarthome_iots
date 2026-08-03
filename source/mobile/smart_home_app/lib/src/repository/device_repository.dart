import 'dart:developer';

import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/service/base_service.dart';

class DeviceRepository extends IDeviceResponsitory {
  final BaseService baseService;

  DeviceRepository({required this.baseService});

  @override
  Future<List<Devices>> getDevices() async {
    try {
      final result = await baseService.dio.get("/api/Devices");
      final list = result.data as List;
      return list.map((e) => Devices.fromJson(e)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<void> updateDevices(Devices devices) async {
    try {
      await baseService.dio.put("/api/Devices/${devices.deviceId ?? ''}",
          data: devices.toJson());
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  Future<List<Schedule>> getListSchedules() async {
    try {
      final result = await baseService.dio.get("/api/Schedules");
      final list = result.data as List;
      return list.map((e) => Schedule.fromJson(e)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      log('${schedule.toJson()}');
      await baseService.dio
          .put("/api/Schedules/${schedule.id ?? ''}", data: schedule.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Schedule>> getListSchedulesByDevice(String deviceId) async {
    try {
      final result =
          await baseService.dio.get("/api/Schedules/deviceallinfo/$deviceId");
      final list = result.data as List;
      return list.map((e) => Schedule.fromJson(e)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<List<PowerUsage>> getListPowerUsage() async {
    try {
      final result = await baseService.dio.get("/api/UsagePowerLogs");
      final list = result.data as List;
      return list.map((e) => PowerUsage.fromJson(e)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<List<PowerUsage>> getPowerUsageByRange(
      String userId, DateTime from, DateTime to) async {
    try {
      final result = await baseService.dio.get(
        '/api/UsagePowerLogs/byUserRange/$userId',
        queryParameters: {
          'startDate': from.toIso8601String(),
          'endDate': to.toIso8601String(),
        },
      );
      final list = result.data as List;
      return list.map((e) => PowerUsage.fromJson(e)).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  Future<Schedule?> onAddSchedule(Schedule schedule) async {
    try {
      print(schedule.toJson());
      final result =
          await baseService.dio.post("/api/Schedules", data: schedule.toJson());
      return Schedule.fromJson(result.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> onUpdateSchedule(Schedule schedule) async {
    try {
      log('[DeviceRepository] PUT /api/Schedules/${schedule.id} body=${schedule.toJson()}');
      await baseService.dio
          .put("/api/Schedules/${schedule.id ?? ''}", data: schedule.toJson());
    } catch (e) {
      log('[DeviceRepository] onUpdateSchedule error: $e');
      rethrow;
    }
  }

  @override
  Future<Devices?> onAddDevice(Devices devices) async {
    try {
      print(devices.toJson());
      final result =
          await baseService.dio.post("/api/Devices", data: devices.toJson());
      return Devices.fromJson(result.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> onUpdateDevice(Devices devices) async {
    try {
      await baseService.dio.put("/api/Devices/${devices.deviceId ?? ''}",
          data: devices.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await baseService.dio.delete("/api/Schedules/$id");
    } catch (e) {
      rethrow;
    }
  }
}
