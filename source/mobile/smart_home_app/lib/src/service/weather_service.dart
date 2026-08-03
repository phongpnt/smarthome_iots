import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

const String _kOpenWeatherApiKey = 'f2dc60c42a3026b72ffccfa1909101e6';

class WeatherData {
  final double tempCelsius;
  final String description;  // e.g. "Cloudy", "Clear"
  final String cityName;
  final String country;
  final int humidity;  // %
  final double windSpeed;  // km/h
  final double visibility;  // km
  final DateTime time;

  const WeatherData({
    required this.tempCelsius,
    required this.description,
    required this.cityName,
    required this.country,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
    required this.time,
  });
}

class WeatherService {
  final WeatherFactory _wf = WeatherFactory(
    _kOpenWeatherApiKey,
    language: Language.ENGLISH,
  );

  Future<WeatherData> fetchCurrentWeather() async {
    final position = await _getCurrentPosition();
    final w = await _wf.currentWeatherByLocation(
      position.latitude,
      position.longitude,
    );
    return WeatherData(
      tempCelsius: w.temperature?.celsius ?? 0,
      description: _capitalize(w.weatherDescription ?? w.weatherMain ?? ''),
      cityName: w.areaName ?? '',
      country: w.country ?? '',
      humidity: (w.humidity ?? 0).toInt(),
      windSpeed: ((w.windSpeed ?? 0) * 3.6),  // m/s → km/h
      visibility: 0.0,  // weather pkg v3.x không expose visibility
      time: w.date ?? DateTime.now(),
    );
  }

  Future<Position> _getCurrentPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return _defaultPosition();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return _defaultPosition();
    }
  }

  Position _defaultPosition() => Position(
        latitude: 10.7769,
        longitude: 106.7009,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
