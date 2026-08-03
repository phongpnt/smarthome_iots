import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/home/home_controller.dart';
import 'package:smart_home_app/src/service/weather_service.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => WeatherService());
    Get.put(HomeController(
      deviceService: Get.find(),
      weatherService: Get.find(),
    ));
  }
}
