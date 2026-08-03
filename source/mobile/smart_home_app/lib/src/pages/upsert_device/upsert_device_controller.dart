import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_argument.dart';

import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/widgets/flash/toast.dart';

class UpsertDeviceController extends GetxController {
  final DeviceService deviceService;
  final UpsertDeviceArgument? arguments;
  final AccountService accountService;
  final IDeviceResponsitory deviceResponsitory;

  UpsertDeviceController({
    this.arguments,
    required this.accountService,
    required this.deviceService,
    required this.deviceResponsitory,
  });

  final deviceName = TextEditingController();
  final location = TextEditingController();
  final description = TextEditingController();
  final ssid = TextEditingController();
  final passWifi = TextEditingController();
  final deviceMac = TextEditingController();
  final devicePowerStatus = Rx(false);
  final type = Rx(DeviceType.air);
  final isLoading = Rx(false);

  @override
  void onInit() {
    super.onInit();
    deviceName.text = arguments?.devices?.deviceName ?? '';
    location.text = arguments?.devices?.location ?? '';
    description.text = arguments?.devices?.description ?? '';
    ssid.text = arguments?.devices?.ssid ?? '';
    passWifi.text = arguments?.devices?.passWifi ?? '';
    deviceMac.text = arguments?.devices?.deviceId ?? arguments?.id ?? '';
    devicePowerStatus.value = arguments?.devices?.powerStatus ?? false;
    type.value = arguments?.devices?.type ?? DeviceType.air;
  }

  @override
  void onClose() {
    deviceName.dispose();
    location.dispose();
    description.dispose();
    ssid.dispose();
    passWifi.dispose();
    deviceMac.dispose();
    devicePowerStatus.close();
    type.close();
    isLoading.close();
    super.onClose();
  }

  void onAddDevice() async {
    final mac = deviceMac.text.trim().toLowerCase().replaceAll(':', '').replaceAll('-', '');
    if (mac.isEmpty) {
      showToast('Vui lòng nhập MAC address của thiết bị');
      return;
    }
    isLoading.value = true;
    final result = await deviceResponsitory.onAddDevice(Devices(
      description: description.text,
      powerStatus: devicePowerStatus.value,
      location: location.text,
      deviceName: deviceName.text,
      ssid: ssid.text,
      userId: accountService.account?.userId,
      createdDate: DateTime.now().toIso8601String(),
      passWifi: passWifi.text,
      type: type.value,
      deviceId: mac,
    ));
    if (result != null) {
      deviceService.onAddDevice(result);
      Get.back(result: result);
    } else {
      showToast('Thông tin không hợp lệ');
    }
    isLoading.value = false;
  }

  void onUpdateDevice() async {
    isLoading.value = true;
    try {
      final device = Devices(
        description: description.text,
        powerStatus: devicePowerStatus.value,
        location: location.text,
        ssid: ssid.text,
        passWifi: passWifi.text,
        type: type.value,
        deviceId: arguments?.devices?.deviceId ?? '',
      );
      await deviceResponsitory.onUpdateDevice(device);
      deviceService.onUpdateDevice(device);
      Get.back(result: device);
    } catch (e) {
      showToast('Thông tin không hợp lệ');
    }
    isLoading.value = false;
  }
}
