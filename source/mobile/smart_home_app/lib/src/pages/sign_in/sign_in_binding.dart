import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/sign_in/sign_in_controller.dart';

class SignInBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SignInController(
          accountResponsitory: Get.find(),
          localStorage: Get.find(),
        ));
  }
}
