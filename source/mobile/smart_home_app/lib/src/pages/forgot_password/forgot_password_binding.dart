import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/forgot_password/forgot_password_controller.dart';

class ForgotPasswordBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ForgotPasswordController(
      accountResponsitory: Get.find(),
    ));
  }
}
