import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_controller.dart';

class UpsertDeviceBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(UpsertDeviceController(
        accountService: Get.find(),
        deviceService: Get.find(),
        deviceResponsitory: Get.find(),
        arguments: Get.arguments));
  }
}
