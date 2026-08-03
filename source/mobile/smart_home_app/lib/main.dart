import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/app.dart';
import 'package:smart_home_app/src/repository/account_responsitory.dart';
import 'package:smart_home_app/src/repository/device_repository.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';
import 'package:smart_home_app/src/repository/power_usage_repository.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/base_service.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/service/local_storage.dart';
import 'package:smart_home_app/src/service/mqtt_service.dart';
import 'package:smart_home_app/src/service/network/account_rest_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localStorage = LocalStorage();
  await localStorage.onInitStorage();
  Get.put<LocalStorage>(localStorage);
  final baseService = BaseService(localStorage: Get.find());
  Get.put<BaseService>(baseService);
  Get.put<AccountRestAPI>(AccountRestAPI(baseService.dio, baseUrl: ''));
  Get.put<IAccountResponsitory>(AccountResponsitory(
      localStorage: Get.find(),
      accountRestAPI: Get.find(),
      baseService: baseService));
  Get.put<AccountService>(AccountService(accountResponsitory: Get.find()));
  Get.put<IDeviceResponsitory>(DeviceRepository(baseService: Get.find()));
  Get.put<IPowerUsageRepository>(PowerUsageRepository(
      baseService: baseService, accountService: Get.find()));
  Get.put<MqttService>(MqttService());
  Get.put<DeviceService>(DeviceService(
      deviceResponsitory: Get.find(),
      mqttService: Get.find(),
      accountService: Get.find()));
  runApp(App());
}
