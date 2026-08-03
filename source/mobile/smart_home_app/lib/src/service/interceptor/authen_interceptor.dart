import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/service/local_storage.dart';

class AuthenInterceptor extends InterceptorsWrapper {
  final LocalStorage localStorage;

  AuthenInterceptor({required this.localStorage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = localStorage.token;
    if (token.isNotEmpty) {
      options.headers.putIfAbsent("Authorization", () => 'Bearer $token');
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      localStorage.clear();
      Get.toNamed(RouteName.SIGN_IN);
    }
    super.onError(err, handler);
  }
}
