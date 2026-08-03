import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';

abstract class BasePage<T extends GetLifeCycleBase> extends GetWidget<T> {
  bool get isSafeArea => false;

  bool get resizeToAvoidBottomInset => true;

  Color get backgroundColor => AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(
        top: isSafeArea,
        bottom: isSafeArea,
        left: isSafeArea,
        right: isSafeArea,
        child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: buildChild(context)),
      ),
    );
  }

  Widget buildChild(BuildContext context);
}
