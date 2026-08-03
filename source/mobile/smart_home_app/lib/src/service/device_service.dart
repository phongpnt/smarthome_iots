import 'dart:async';
import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/mqtt_service.dart';

class DeviceService extends GetxService {
  final IDeviceResponsitory deviceResponsitory;
  final MqttService mqttService;
  final AccountService accountService;

  DeviceService({
    required this.deviceResponsitory,
    required this.mqttService,
    required this.accountService,
  });

  final devices = Rx<List<Devices>?>(null);
  final schedules = Rx<List<Schedule>?>(null);
  final usages = Rx<List<PowerUsage>?>(null);

  StreamSubscription? _relayStateSub;

  @override
  void onInit() {
    super.onInit();
    mqttService.connect();
    _relayStateSub = mqttService.relayStateStream.listen((data) {
      final deviceId = data['device_id'] as String?;
      final relayStatus = data['relay_status'] as String?;
      if (deviceId == null || relayStatus == null) return;
      final isOn = relayStatus == 'on';
      final list = devices.value;
      if (list == null) return;
      final idx = list.indexWhere((d) => d.deviceId == deviceId);
      if (idx == -1) return;
      final updated = list[idx].copyWith(powerStatus: isOn);
      final newList = [...list];
      newList[idx] = updated;
      devices.value = newList;
      print('[DeviceService] Relay state from firmware: $deviceId → ${isOn ? "ON" : "OFF"}');
    });
  }

  @override
  void onClose() {
    _relayStateSub?.cancel();
    super.onClose();
  }

  Future<void> onGetDevices() async {
    final all = await deviceResponsitory.getDevices();
    final myUserId = accountService.account?.userId;
    devices.value = myUserId != null
        ? all.where((d) => d.userId == myUserId).toList()
        : all;
    await onGetSchedule();
  }

  void onAddSchedule(Schedule schedule) {
    final deviceIndex =
        devices.value?.indexWhere((d) => d.deviceId == schedule.deviceId) ?? -1;
    final enriched = deviceIndex >= 0
        ? schedule.copyWith(devices: devices.value![deviceIndex])
        : schedule;
    final list = [...schedules.value!, enriched];
    schedules.value = list;
    _pushScheduleToFirmware(list);
  }

  void onUpdateSchedule(Schedule schedule) {
    final list = [...schedules.value!];
    final index = list.indexWhere((element) => element.id == schedule.id);
    if (index != -1) {
      list[index] = schedule;
      schedules.value = list;
    }
    _pushScheduleToFirmware(schedules.value ?? []);
  }

  void _pushScheduleToFirmware(List<Schedule> list) {
    mqttService.publishScheduleUpdate(list);
  }

  void onAddDevice(Devices device) {
    final list = [...devices.value!, device];
    devices.value = list;
  }

  void onUpdateDevice(Devices device) {
    final list = [...devices.value!];
    final index =
        list.indexWhere((element) => element.deviceId == device.deviceId);
    if (index != -1) {
      list[index] = device;
      devices.value = list;
    }
  }

  Future<void> onChangeStatus(int index, bool value) async {
    final list = [...devices.value!];
    final newDevice = list[index].copyWith(powerStatus: value);

    list[index] = newDevice;
    devices.value = [...list];

    final deviceId = newDevice.deviceId ?? '';
    if (deviceId.isNotEmpty) {
      mqttService.publishRelayCommand(deviceId, value);
    }

    try {
      await deviceResponsitory.updateDevices(newDevice);
    } catch (e) {
      print('[DeviceService] updateDevices sync error: $e');
    }
  }

  Future<void> onGetSchedule() async {
    final result = await deviceResponsitory.getListSchedules();
    for (var i = 0; i < result.length; i++) {
      final schedule = result[i];
      final index = devices.value
              ?.indexWhere((val) => val.deviceId == schedule.deviceId) ??
          -1;
      if (index != -1) {
        result[i] = schedule.copyWith(devices: devices.value![index]);
      }
    }
    schedules.value = result;
  }

  Future<void> onGetPowerUsage() async {
    final result = await deviceResponsitory.getListPowerUsage();
    for (var i = 0; i < result.length; i++) {
      final usage = result[i];
      final index =
          devices.value?.indexWhere((val) => val.deviceId == usage.deviceId) ??
              -1;
      if (index != -1) {
        result[i] = usage.copyWith(devices: devices.value![index]);
      }
    }
    result.sort((a, b) {
      final dateA = DateTime.tryParse(a.calculateDate ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b.calculateDate ?? '') ?? DateTime(0);
      return dateB.compareTo(dateA);  // newest first
    });
    usages.value = result;
  }

  Future<void> onUpdatePowerStatusSchedule(int index, bool value) async {
    final list = [...schedules.value!];
    final newDevice = list[index].copyWith(active: value);

    list[index] = newDevice;
    schedules.value = [...list];

    try {
      await deviceResponsitory.updateSchedule(newDevice);
    } catch (e) {
      print('[DeviceService] updateSchedule sync error: $e');
    }
  }

  void updateSchedule(Schedule schedule) {
    final list = [...schedules.value!];
    final index = list.indexWhere((element) => element.id == schedule.id);
    if (index != -1) {
      list[index] = schedule;
      schedules.value = [...list];
    }
  }

  Future<bool> onDeleteSchedule(int index) async {
    final list = [...schedules.value!];
    final schedule = list[index];
    final scheduleId = schedule.id ?? '';

    print('[DeviceService] onDeleteSchedule: id=$scheduleId, name=${schedule.deviceName}');

    if (scheduleId.isEmpty) {
      print('[DeviceService] onDeleteSchedule: schedule.id is empty — aborting');
      return false;
    }

    list.removeAt(index);
    schedules.value = [...list];

    try {
      await deviceResponsitory.deleteSchedule(scheduleId);
      print('[DeviceService] onDeleteSchedule: API success, id=$scheduleId');
      _pushScheduleToFirmware(schedules.value ?? []);
      return true;
    } catch (e) {
      print('[DeviceService] onDeleteSchedule: API error — $e');
      list.insert(index, schedule);
      schedules.value = [...list];
      return false;
    }
  }
}
