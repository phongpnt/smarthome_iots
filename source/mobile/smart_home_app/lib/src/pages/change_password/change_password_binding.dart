import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/change_password/change_password_controller.dart';

class ChangePasswordBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ChangePasswordController(
        accountResponsitory: Get.find(), accountService: Get.find()));
  }
}
