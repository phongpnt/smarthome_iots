import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/temp/_controller.dart';

class Binding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => Controller());
  }
}
