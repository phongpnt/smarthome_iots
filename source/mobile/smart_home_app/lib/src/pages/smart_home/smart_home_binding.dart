import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/smart_home/smart_home_controller.dart';

class SmartHomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(() => SmartHomeController(
          deviceService: Get.find(),
          deviceResponsitory: Get.find(),
        ));
  }
}
