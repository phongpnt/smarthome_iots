import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/widgets/flash/toast.dart';

class SmartHomeController extends GetxController {
  final DeviceService deviceService;
  final IDeviceResponsitory deviceResponsitory;

  SmartHomeController({
    required this.deviceService,
    required this.deviceResponsitory,
  });

  Future<void> onDeleteSchedule(int index) async {
    final list = <Schedule>[...(deviceService.schedules.value ?? [])];
    if (index >= list.length) return;
    final schedule = list[index];
    final scheduleId = schedule.id ?? '';
    if (scheduleId.isEmpty) {
      showToast('Lịch hẹn thiếu ID, không thể xóa');
      return;
    }
    list.removeAt(index);
    deviceService.schedules.value = [...list];
    try {
      await deviceResponsitory.deleteSchedule(scheduleId);
      showToast('Đã xóa lịch hẹn');
    } catch (e) {
      list.insert(index, schedule);
      deviceService.schedules.value = [...list];
      showToast('Xóa lịch hẹn thất bại');
    }
  }
}
