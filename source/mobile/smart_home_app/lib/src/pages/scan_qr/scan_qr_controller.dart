import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRController extends GetxController {
  final MobileScannerController scannerController = MobileScannerController();

  void onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      scannerController.stop();
      Get.back(result: barcode!.rawValue);
    }
  }

  @override
  void onClose() {
    scannerController.dispose();
    super.onClose();
  }
}
