import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_argument.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_argument.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';

class VerifyOTPController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  final VerifyOTPArgument argument;
  final loading = false.obs;
  final error = ''.obs;

  VerifyOTPController(
      {required this.accountResponsitory, required this.argument});

  final textCtrl = TextEditingController();
  final lengthOtp = 6;

  @override
  void onInit() {
    super.onInit();
    textCtrl.addListener(() {
      if (error.isNotEmpty) {
        error.value = '';
      }
    });
  }

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  void onSubmit() async {
    error.value = '';
    if (textCtrl.text.length != lengthOtp) {
      error.value = 'Mã OTP không hợp lệ';
      return;
    }

    loading.value = true;
    try {
      await accountResponsitory.verifyOTP(argument.email, textCtrl.text);
      Get.toNamed(RouteName.RESET_PASSWORD,
          arguments:
              ResetPasswordArgument(email: argument.email, otp: textCtrl.text));
    } catch (e) {
      print(e);
      error.value = 'Mã OTP không hợp lệ';
    }

    loading.value = false;
  }
}
