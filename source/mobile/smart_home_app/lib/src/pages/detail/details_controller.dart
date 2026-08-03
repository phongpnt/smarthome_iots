import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage_chart.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/pages/detail/detail_agurement.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/service/mqtt_service.dart';
import 'package:smart_home_app/src/widgets/flash/toast.dart';

class DetailsController extends GetxController {
  final DetailsAgurement agurement;
  final IDeviceResponsitory deviceResponsitory;
  final DeviceService deviceService;
  final IPowerUsageRepository powerUsageRepository;
  final MqttService mqttService;

  DetailsController({
    required this.agurement,
    required this.deviceResponsitory,
    required this.deviceService,
    required this.powerUsageRepository,
    required this.mqttService,
  });

  late final Rx<Devices> devices;
  final schedules = Rx<List<Schedule>?>(null);
  final today = Rx<List<PowerUsaegChart>?>(null);
  final week = Rx<List<PowerUsaegChart>?>(null);
  final month = Rx<List<PowerUsaegChart>?>(null);

  @override
  void onInit() async {
    super.onInit();
    devices = Rx(agurement.devices);
    ever(deviceService.devices, (List<dynamic>? list) {
      if (list == null) return;
      final updated = list.firstWhereOrNull(
          (d) => (d as dynamic).deviceId == devices.value.deviceId);
      if (updated != null && updated != devices.value) {
        devices.value = updated as Devices;
      }
    });
    onRefresh();
  }

  Future<void> onRefresh() async {
    schedules.value = null;
    today.value = null;
    week.value = null;
    month.value = null;
    final result = await Future.wait([
      deviceResponsitory
          .getListSchedulesByDevice(agurement.devices.deviceId ?? ''),
      powerUsageRepository.getPowerChartByDeviceId(
          agurement.devices.deviceId ?? '',
          filter: ChartFilter.day),
      powerUsageRepository.getPowerChartByDeviceId(
          agurement.devices.deviceId ?? '',
          filter: ChartFilter.week),
      powerUsageRepository.getPowerChartByDeviceId(
          agurement.devices.deviceId ?? '',
          filter: ChartFilter.month)
    ]);
    schedules.value = result[0] as List<Schedule>;
    today.value = result[1] as List<PowerUsaegChart>;
    week.value = result[2] as List<PowerUsaegChart>;
    month.value = result[3] as List<PowerUsaegChart>;
  }

  Future<void> onUpdatePowerStatusDevice(bool value) async {
    final newDevice = devices.value.copyWith(powerStatus: value);
    try {
      await deviceResponsitory.updateDevices(newDevice);
      devices.value = newDevice;
      final deviceId = newDevice.deviceId ?? '';
      if (deviceId.isNotEmpty) {
        mqttService.publishRelayCommand(deviceId, value);
      }
    } catch (e) {
      print(e);
      showToast("Update power status fail");
    }
  }

  Future<void> onUpdatePowerStatusSchedule(int index, bool value) async {
    final list = [...schedules.value!];
    final newDevice = list[index].copyWith(active: value);
    try {
      await deviceResponsitory.updateSchedule(newDevice);
      list[index] = newDevice;
      schedules.value = list;
      deviceService.updateSchedule(newDevice);
    } catch (e) {
      print(e);
    }
  }

  void onAddSchedule(Schedule schedule) {
    if (schedule.deviceId == devices.value.deviceId) {
      final list = [...schedules.value!];
      schedules.value = [...list, schedule];
    }
  }

  Future<void> onDeleteSchedule(int index) async {
    final list = [...schedules.value!];
    final schedule = list[index];
    final scheduleId = schedule.id ?? '';

    print('[DetailsController] onDeleteSchedule: id=$scheduleId');

    if (scheduleId.isEmpty) {
      showToast('Lịch hẹn thiếu ID, không thể xóa');
      return;
    }

    list.removeAt(index);
    schedules.value = [...list];
    final dsSchedules = <Schedule>[...(deviceService.schedules.value ?? [])];
    final dsIndex = dsSchedules.indexWhere((s) => s.id == scheduleId);
    if (dsIndex != -1) dsSchedules.removeAt(dsIndex);
    deviceService.schedules.value = dsSchedules;

    try {
      await deviceResponsitory.deleteSchedule(scheduleId);
      print('[DetailsController] onDeleteSchedule: API success');
      showToast('Đã xóa lịch hẹn');
    } catch (e) {
      print('[DetailsController] onDeleteSchedule: API error — $e');
      list.insert(index, schedule);
      schedules.value = [...list];
      if (dsIndex != -1) {
        dsSchedules.insert(dsIndex, schedule);
        deviceService.schedules.value = [...dsSchedules];
      }
      showToast('Xóa lịch hẹn thất bại');
    }
  }

  void onUpdateSchedule(Schedule schedule) {
    final list = [...schedules.value!];
    final index = list.indexWhere((element) => element.id == schedule.id);
    if (index == -1) return;
    if (schedule.deviceId == devices.value.deviceId) {
      list[index] = schedule;
    } else {
      list.removeAt(index);
    }
    schedules.value = [...list];
  }

  @override
  void onClose() {
    devices.close();
    today.close();
    month.close();
    week.close();
    schedules.close();
    super.onClose();
  }
}
