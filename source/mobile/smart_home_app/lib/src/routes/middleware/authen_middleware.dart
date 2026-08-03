import 'package:flutter/src/widgets/navigator.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/service/local_storage.dart';

class AuthenMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isLogin = Get.find<LocalStorage>().email.isNotEmpty;
    final routeLogin = route == RouteName.SIGN_IN ||
        route == RouteName.RESET_PASSWORD ||
        route == RouteName.FORGOT_PASSWORD ||
        route == RouteName.SIGN_UP ||
        route == RouteName.VERIFY_OTP;
    if (!isLogin && !routeLogin) {
      return RouteSettings(name: RouteName.SIGN_IN);
    }
    return super.redirect(route);
  }
}
