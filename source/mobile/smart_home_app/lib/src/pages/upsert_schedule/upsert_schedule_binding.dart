import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_controller.dart';

class UpsertScheduleBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(UpsertScheduleController(
        arguments: Get.arguments,
        deviceService: Get.find(),
        deviceResponsitory: Get.find()));
  }
}
