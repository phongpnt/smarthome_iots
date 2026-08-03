import 'package:get/get.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/service/weather_service.dart';

class HomeController extends GetxController {
  final DeviceService deviceService;
  final WeatherService weatherService;

  HomeController({
    required this.deviceService,
    required this.weatherService,
  });

  final weather = Rx<WeatherData?>(null);
  final weatherError = RxString('');

  @override
  void onInit() {
    super.onInit();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    weatherError.value = '';
    try {
      final data = await weatherService.fetchCurrentWeather();
      weather.value = data;
    } catch (e) {
      weatherError.value = e.toString();
      print('[Weather] Error: $e');
    }
  }

  Future<void> onRefresh() async {
    await Future.wait([
      deviceService.onGetDevices(),
      fetchWeather(),
    ]);
  }
}
