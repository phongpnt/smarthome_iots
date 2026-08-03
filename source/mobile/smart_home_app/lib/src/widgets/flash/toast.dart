import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/widgets/flash/flash.dart';

void showToast(
  String title, {
  bool? isWarningToast = false,
  Color? color,
  String? imagePath,
  Widget? iconWidget,
  bool isTopPosition = true,
  TextStyle? titleTextStyle,
  TextStyle? contentTextStyle,
  Function()? onTap,
}) {
  showFlash(
    context: Get.context!,
    duration: const Duration(seconds: 3),
    builder: (_, controller) {
      return Flash(
        borderRadius: BorderRadius.circular(8),
        margin: setPadding(all: 24),
        controller: controller,
        backgroundColor: Colors.white,
        boxShadows: const [],
        barrierDismissible: true,
        behavior: FlashBehavior.floating,
        position: isTopPosition ? FlashPosition.top : FlashPosition.bottom,
        onTap: () async {
          await controller.dismiss();
          if (onTap != null) {
            onTap()!;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: setPadding(horizontal: 8, vertical: 12),
              child: Text(
                title,
                style: titleTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showSimpleToast(String content) {
  showFlash(
    context: Get.context!,
    duration: const Duration(seconds: 2),

    builder: (_, controller) {
      return Flash(
        borderRadius: BorderRadius.circular(8),
        margin: setPadding(all: 24),
        controller: controller,
        barrierDismissible: true,
        behavior: FlashBehavior.floating,
        position: FlashPosition.bottom,
        child: Container(
          height: height(42),
          padding: setPadding(horizontal: 38),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                content,
              ),
            ],
          ),
        ),
      );
    },
  );
}
