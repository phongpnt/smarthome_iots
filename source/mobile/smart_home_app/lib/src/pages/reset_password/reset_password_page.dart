import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_login_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_controller.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field.dart';

class ResetPasswordPage extends BaseLoginPage<ResetPasswordController> {
  @override
  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: Get.back,
              child: Icon(Icons.arrow_back_ios_outlined,
                  size: 24, color: AppColors.primaryColor),
            ),
            Text('Đặt lại mật khẩu',
                style: TextStyle(
                  fontSize: 24,
                  color: AppColors.primaryColor,
                )),
          ],
        ),
        SizedBox(height: 12),
        CustomTextField(
          isPassword: true,
          model: controller.password,
          hint: 'Mật khẩu mới',
        ),
        SizedBox(height: 12),
        CustomTextField(
          model: controller.confirmPassword,
          isPassword: true,
          hint: 'Xác nhận mật khẩu mới',
        ),
        SizedBox(height: 12),
        Obx(
          () => PrimaryButton(
            buttonText: 'Xác nhận',
            isLoading: controller.loading.value,
            onTap: controller.textFormModel.validate,
          ),
        ),
      ],
    );
  }
}
