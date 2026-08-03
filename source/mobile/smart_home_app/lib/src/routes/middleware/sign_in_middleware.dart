import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/service/local_storage.dart';

class SignInMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final localStorage = Get.find<LocalStorage>();
    final isLogin =
        localStorage.email.isNotEmpty && localStorage.token.isNotEmpty;

    if (isLogin) {
      return RouteSettings(name: RouteName.HOME);
    }
    return super.redirect(route);
  }
}
