import 'dart:io';  // Nhớ thêm import này
import 'package:dio/io.dart';  // Và cái này nữa
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/service/interceptor/authen_interceptor.dart';
import 'package:smart_home_app/src/service/local_storage.dart';

class BaseService extends GetxService {
  final LocalStorage localStorage;
  late final Dio dio;

  BaseService({required this.localStorage});

  @override
  void onInit() {
    super.onInit();
    dio = Dio(BaseOptions(baseUrl: 'https://iots.bhbl.vn'));
    if (kDebugMode) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    dio.interceptors.add(AuthenInterceptor(localStorage: localStorage));
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor());
    }
  }
}
