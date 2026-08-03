import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';

abstract class BaseHomePage<T extends GetLifeCycleBase> extends BasePage<T> {
  double get radiusView => 40;

  double? get topRadius => null;

  double? get bottomRadius => null;

  Color get bodyBackground => AppColors.morelightgrey;

  @override
  Widget buildChild(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: appBarPadding,
          decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(topRadius ?? radiusView))),
          child: buildAppbar(context),
        ),
        Expanded(
          child: Container(
            padding: bodyPadding,
            decoration: BoxDecoration(gradient: AppColors.headerGradient),
            child: Container(
              decoration: BoxDecoration(
                color: bodyBackground,
                borderRadius: BorderRadius.only(
                    topRight: Radius.circular(bottomRadius ?? radiusView)),
              ),
              child: buildBody(context),
            ),
          ),
        ),
      ],
    );
  }

  EdgeInsets get appBarPadding => EdgeInsets.zero;

  EdgeInsets get bodyPadding => EdgeInsets.zero;

  Widget buildAppbar(BuildContext context);

  Widget buildBody(BuildContext context);
}
