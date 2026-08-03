import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_controller.dart';

class ResetPasswordBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ResetPasswordController(
      accountResponsitory: Get.find(),
      resetPasswordArgument: Get.arguments,
    ));
  }
}
