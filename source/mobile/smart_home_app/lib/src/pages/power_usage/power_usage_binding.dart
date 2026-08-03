import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_controller.dart';

class PowerUsageBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(() => PowerUsageController(
          deviceResponsitory: Get.find(),
          deviceService: Get.find(),
          powerUsageRepository: Get.find(),
          accountService: Get.find(),
        ));
  }
}
