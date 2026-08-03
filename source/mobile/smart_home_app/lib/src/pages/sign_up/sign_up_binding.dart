import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/sign_up/sign_up_controller.dart';

class SignUpBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(SignUpController(
      accountResponsitory: Get.find(),
      localStorage: Get.find(),
    ));
  }
}
