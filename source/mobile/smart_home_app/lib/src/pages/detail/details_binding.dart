import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/detail/details_controller.dart';

class DetailsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(DetailsController(
      agurement: Get.arguments,
      powerUsageRepository: Get.find(),
      deviceResponsitory: Get.find(),
      deviceService: Get.find(),
      mqttService: Get.find(),
    ));
  }
}
