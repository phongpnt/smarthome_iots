import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/device_service.dart';

class MainController extends GetxController {
  final AccountService accountService;
  final DeviceService deviceService;

  MainController({required this.accountService, required this.deviceService});

  final pageCtrl = PageController();
  final currentIndex = 0.obs;
  final unreadWarnings = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    await accountService.onGetUserProfile();
    await deviceService.onGetDevices();
  }

  void onChangePage(int index) {
    currentIndex.value = index;
    pageCtrl.jumpToPage(index);
    if (index == 2) {
      deviceService.onGetPowerUsage();
    }
  }

  @override
  void onClose() {
    pageCtrl.dispose();
    super.onClose();
  }
}
