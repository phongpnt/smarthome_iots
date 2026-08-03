import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/scan_qr/scan_qr_controller.dart';

class ScanQRPage extends BaseHomePage<ScanQRController> {
  @override
  Widget buildAppbar(BuildContext context) => SafeArea(
        child: Container(
          padding: setPadding(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                  onTap: Get.back,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 24, color: AppColors.white)),
              SizedBox(width: width(12)),
              Expanded(
                child: Text(
                  'Quét mã QR',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white),
                ),
              )
            ],
          ),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return MobileScanner(
      controller: controller.scannerController,
      onDetect: controller.onDetect,
    );
  }
}
