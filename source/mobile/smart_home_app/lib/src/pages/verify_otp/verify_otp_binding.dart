import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_controller.dart';

class VerifyOTPBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(VerifyOTPController(
      accountResponsitory: Get.find(),
      argument: Get.arguments,
    ));
  }
}
