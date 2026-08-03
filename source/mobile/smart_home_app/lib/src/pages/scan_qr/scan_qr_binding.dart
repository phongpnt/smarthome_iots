import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/scan_qr/scan_qr_controller.dart';

class ScanQRBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ScanQRController());
  }
}
