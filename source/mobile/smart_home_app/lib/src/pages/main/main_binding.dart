import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/ai_chat/ai_chat_controller.dart';
import 'package:smart_home_app/src/pages/home/home_controller.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_controller.dart';
import 'package:smart_home_app/src/pages/smart_home/smart_home_controller.dart';
import 'package:smart_home_app/src/service/ai_service.dart';
import 'package:smart_home_app/src/service/weather_service.dart';

class MainBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(
        MainController(accountService: Get.find(), deviceService: Get.find()));
    Get.lazyPut(() => WeatherService());
    Get.put(HomeController(
        deviceService: Get.find(), weatherService: Get.find()));
    Get.put(SmartHomeController(
      deviceService: Get.find(),
      deviceResponsitory: Get.find(),
    ));
    Get.put(
      PowerUsageController(
          powerUsageRepository: Get.find(),
          deviceResponsitory: Get.find(),
          accountService: Get.find(),
          deviceService: Get.find()),
    );
    Get.put(AiService(baseService: Get.find()));
    Get.put(AiChatController(
        aiService: Get.find(), accountService: Get.find()));
  }
}
