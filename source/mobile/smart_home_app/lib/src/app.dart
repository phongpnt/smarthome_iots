import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/config/app_them.dart';
import 'package:smart_home_app/src/routes/app_route.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.appTheme,
      getPages: AppRoute.pages,
      initialRoute: RouteName.SIGN_IN,
    );
  }
}
