import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/config/app_utils.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_parameter.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/widgets/flash/toast.dart';
import 'package:uuid/uuid.dart';

class UpsertScheduleController extends GetxController {
  final UpsertScheduleParameter? arguments;
  final DeviceService deviceService;
  final IDeviceResponsitory deviceResponsitory;

  UpsertScheduleController(
      {this.arguments,
      required this.deviceService,
      required this.deviceResponsitory});

  final dayOfWeek = Rx('1');
  final time = Rx(TimeOfDay.now());
  final device = Rx('');
  final error = Rx('');
  final active = Rx(false);
  final powerStatus = Rx(false);
  final descriptionCtrl = TextEditingController();
  final isLoading = Rx(false);

  Devices? get currentDevice {
    return deviceService.devices.value
        ?.firstWhereOrNull((element) => element.deviceId == device.value);
  }

  String get timeText {
    return '${getTime(time.value.hour)}:${getTime(time.value.minute)}';
  }

  @override
  void onInit() {
    super.onInit();
    dayOfWeek.value = arguments?.schedule?.dayOfWeek ?? '1';
    if ((arguments?.schedule?.time ?? '').isNotEmpty) {
      final scheduleTime = arguments!.schedule!.time!;
      final split = scheduleTime.split(':');

      time.value = TimeOfDay(
          hour: int.tryParse(split[0]) ?? 0,
          minute: int.tryParse(split[1]) ?? 0);
    }
    powerStatus.value = arguments?.schedule?.powerStatus ?? false;
    active.value = arguments?.schedule?.active ?? false;
    device.value =
        arguments?.devices?.deviceId ?? arguments?.schedule?.deviceId ?? '';
    descriptionCtrl.text = arguments?.schedule?.description ?? '';
  }

  @override
  void onClose() {
    descriptionCtrl.dispose();
    dayOfWeek.close();
    powerStatus.close();
    time.close();
    device.close();
    isLoading.close();
    super.onClose();
  }

  void onUpsertDayOfWeek(String index) {
    if (dayOfWeek.value.contains(index)) {
      dayOfWeek.value = dayOfWeek.value.replaceFirst(index, '');
    } else {
      dayOfWeek.value += index;
    }
  }

  void onAddSchedule() async {
    isLoading.value = true;
    final result = await deviceResponsitory.onAddSchedule(Schedule(
      id: Uuid().v4(),
      description: descriptionCtrl.text,
      dayOfWeek: dayOfWeek.value,
      time: timeText,
      active: active.value,
      powerStatus: powerStatus.value,
      deviceId: device.value,
    ));
    if (result != null) {
      final schedule = result.copyWith(devices: currentDevice);
      deviceService.onAddSchedule(schedule);
      Get.back(result: schedule);
    } else {
      showToast('Dữ liệu lịch không hợp lệ');
    }
    isLoading.value = false;
  }

  void onUpdateSchedule() async {
    isLoading.value = true;

    final scheduleId = arguments?.schedule?.id ?? '';
    final deviceId = device.value;

    if (scheduleId.isEmpty) {
      showToast('Lịch không hợp lệ (thiếu ID)');
      isLoading.value = false;
      return;
    }
    if (deviceId.isEmpty) {
      showToast('Vui lòng chọn thiết bị');
      isLoading.value = false;
      return;
    }
    if (dayOfWeek.value.isEmpty) {
      showToast('Vui lòng chọn ít nhất một ngày');
      isLoading.value = false;
      return;
    }

    try {
      final schedule = Schedule(
        id: scheduleId,
        description: descriptionCtrl.text,
        dayOfWeek: dayOfWeek.value,
        time: timeText,
        active: active.value,
        powerStatus: powerStatus.value,
        deviceId: deviceId,
      );
      debugPrint('[Schedule] PUT payload: ${schedule.toJson()}');
      await deviceResponsitory.onUpdateSchedule(schedule);
      final newSchedule = schedule.copyWith(devices: currentDevice);
      deviceService.onUpdateSchedule(newSchedule);
      Get.back(result: newSchedule);
    } catch (e) {
      debugPrint('[Schedule] onUpdateSchedule error: $e');
      showToast('Cập nhật lịch thất bại');
    }

    isLoading.value = false;
  }
}
